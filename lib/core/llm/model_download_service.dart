import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'model_spec.dart';

/// Downloads and manages on-device LLM model files.
///
/// Downloads land in the app documents directory. The service stores an
/// optional HuggingFace token in secure storage for gated model access.
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
  /// Throws [StateError] if [spec] requires a token and none is stored.
  /// Forwards [DioException] on network errors. Partial files are deleted
  /// on error.
  Stream<(int, int)> download(ReckonModelSpec spec) async* {
    final file = await modelFile(spec);
    final part = await _partFile(spec);
    final controller = StreamController<(int, int)>();

    final headers = <String, dynamic>{};
    if (spec.requiresToken) {
      final token = await getHfToken();
      if (token == null || token.isEmpty) {
        controller.addError(StateError(
          'This model requires a HuggingFace token — add one in Settings.',
        ));
        controller.close();
        yield* controller.stream;
        return;
      }
      headers['Authorization'] = 'Bearer $token';
    }

    // Clear stale artifacts from any previous aborted attempt so a partial
    // `.part` can't be mistaken for fresh progress.
    if (part.existsSync()) await part.delete();

    unawaited(_dio
        .download(
      spec.downloadUrl,
      part.path,
      options: Options(headers: headers),
      onReceiveProgress: (received, total) {
        controller.add((received, total));
      },
      deleteOnError: true,
    )
        .then((_) async {
      // Atomically promote the completed file to its final name. Only now is
      // [isDownloaded] allowed to return true.
      if (file.existsSync()) await file.delete();
      await part.rename(file.path);
      controller.close();
    }, onError: (Object e) {
      controller.addError(e);
      controller.close();
    }));

    yield* controller.stream;
  }

  /// Deletes the local model file (and any leftover `.part`) for [spec].
  Future<void> delete(ReckonModelSpec spec) async {
    final file = await modelFile(spec);
    if (file.existsSync()) await file.delete();
    final part = await _partFile(spec);
    if (part.existsSync()) await part.delete();
  }
}
