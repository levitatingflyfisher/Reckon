import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:domovoi/domovoi.dart' show resumableDownload;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'model_spec.dart';

/// Downloads and manages on-device LLM model files (native builds only).
///
/// The transfer itself is domovoi's shared [resumableDownload] engine
/// (resume-from-byte, 416 recovery, Range-ignoring-host recovery, real
/// cancellation). Downloads land in the app documents directory. The service
/// stores an optional HuggingFace token in secure storage for gated model
/// access. The web build has no on-device model runtime, so it uses the inert
/// `model_download_service_web.dart` variant instead of this file (which needs
/// `dart:io`, `path_provider`, and dio's file download).
class ModelDownloadService {
  ModelDownloadService({
    Dio? dio,
    FlutterSecureStorage? storage,
    Future<Directory> Function()? documentsDirectory,
  })  : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage(),
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Resolves the directory model files live in. Injectable so the
  /// completion/validation logic is testable without platform channels.
  final Future<Directory> Function() _documentsDirectory;

  static const _hfTokenKey = 'reckon.hf_token';

  /// A final model file under this size is treated as junk (0-byte / garbage)
  /// and removed. This is NOT a completeness check against a guessed size —
  /// completeness is guaranteed by the download-to-`.part`-then-rename scheme
  /// in [download], so any file at the final path is a finished transfer.
  static const _minValidBytes = 1024 * 1024; // 1 MB

  /// Returns the local [File] where [spec] will be (or is) stored.
  Future<File> modelFile(ReckonModelSpec spec) async {
    final dir = await _documentsDirectory();
    return File(p.join(dir.path, spec.fileName));
  }

  /// The in-progress download target. Promoted to [modelFile] only on success.
  Future<File> _partFile(ReckonModelSpec spec) async {
    final dir = await _documentsDirectory();
    return File(p.join(dir.path, '${spec.fileName}.part'));
  }

  /// Whether [spec] has already been downloaded to the local file system.
  ///
  /// A completed download is atomically renamed from `<file>.part` to its
  /// final name (see [download]), so the mere existence of the final file
  /// means the transfer finished — we do not, and must not, infer corruption
  /// from a hand-entered [ReckonModelSpec.approximateSizeBytes] (doing so
  /// previously deleted real, correctly-sized models and soft-bricked the
  /// on-device LLM). The size check only rejects an empty/garbage file.
  Future<bool> isDownloaded(ReckonModelSpec spec) async {
    final file = await modelFile(spec);
    if (!file.existsSync()) return false;
    if (await file.length() < _minValidBytes) {
      await file.delete();
      return false;
    }
    return true;
  }

  /// Reads the stored HuggingFace token, if any.
  Future<String?> getHfToken() => _storage.read(key: _hfTokenKey);

  /// Persists a HuggingFace token for gated model downloads.
  Future<void> setHfToken(String token) =>
      _storage.write(key: _hfTokenKey, value: token);

  /// Removes the stored HuggingFace token, if any.
  Future<void> clearHfToken() => _storage.delete(key: _hfTokenKey);

  /// Whether a non-empty HuggingFace token is currently stored.
  Future<bool> hasHfToken() async {
    final token = await getHfToken();
    return token != null && token.isNotEmpty;
  }

  /// Downloads [spec] and yields `(receivedBytes, totalBytes)` progress
  /// tuples. The total may be `-1` if the server omits `Content-Length`.
  ///
  /// Resumable: an interrupted attempt's `.part` is continued with an HTTP
  /// Range request instead of restarting from zero, and the partial is kept
  /// on error so the next attempt picks up where this one stopped (the
  /// engine's contract — see [resumableDownload]).
  ///
  /// Cancelling the subscription is the pause button, for real: it cancels
  /// the underlying transfer, keeps the `.part` for resume, and the file is
  /// never promoted. (The previous implementation detached the writer from
  /// the stream, so a cancelled subscription left it downloading — and
  /// promoting — behind the user's back.)
  ///
  /// Throws [StateError] if [spec] requires a token and none is stored.
  /// Forwards [DioException] on network errors.
  Stream<(int, int)> download(ReckonModelSpec spec) {
    final controller = StreamController<(int, int)>();
    final cancelToken = CancelToken();

    Future<void> run() async {
      final file = await modelFile(spec);
      final part = await _partFile(spec);

      if (spec.requiresToken) {
        final token = await getHfToken();
        if (token == null || token.isEmpty) {
          throw StateError(
            'This model requires a HuggingFace token — add one in Settings.',
          );
        }
        // Base-option headers ride every request the engine makes (initial,
        // 416 restart, Range-ignored restart), like the per-request header
        // used to.
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      try {
        await resumableDownload(
          dio: _dio,
          url: spec.downloadUrl,
          partFile: part,
          cancelToken: cancelToken,
          onProgress: (received, total) =>
              controller.add((received, total ?? -1)),
          // Atomically promote the completed file to its final name. Only
          // after this is [isDownloaded] allowed to return true.
          promote: () async {
            if (file.existsSync()) await file.delete();
            await part.rename(file.path);
          },
        );
      } finally {
        _dio.options.headers.remove('Authorization');
      }
    }

    controller
      ..onListen = () {
        unawaited(run().then((_) => controller.close(), onError: (Object e) {
          controller.addError(e);
          controller.close();
        }));
      }
      ..onCancel = () {
        // Subscription cancel = transfer cancel. The engine then ends the
        // run quietly: partial kept, promote never called.
        if (!cancelToken.isCancelled) cancelToken.cancel();
      };

    return controller.stream;
  }

  /// Deletes the local model file (and any leftover `.part`) for [spec].
  Future<void> delete(ReckonModelSpec spec) async {
    final file = await modelFile(spec);
    if (file.existsSync()) await file.delete();
    final part = await _partFile(spec);
    if (part.existsSync()) await part.delete();
  }
}
