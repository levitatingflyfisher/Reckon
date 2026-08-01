import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';

/// In-memory dio transport. `flutter test` stubs `HttpClient` to fail every
/// real request, so we swap dio's adapter for one that serves bytes from
/// memory — this still drives the *real* dio download/append/`deleteOnError`
/// logic and honours HTTP Range (206) like a real CDN, just without a socket.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.payload, {this.ignoreRange = false, this.errorStatus});

  final List<int> payload;

  /// Simulate a host that ignores `Range` and always returns the whole file.
  final bool ignoreRange;

  /// If set, reply with this status and an empty body (simulates a failure).
  final int? errorStatus;

  /// The `Range` header value seen on each request (null if none was sent).
  final List<String?> rangeHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final range =
        (options.headers['Range'] ?? options.headers['range'])?.toString();
    rangeHeaders.add(range);

    if (errorStatus != null) {
      return ResponseBody.fromBytes(Uint8List(0), errorStatus!);
    }

    var start = 0;
    var status = HttpStatus.ok;
    final headers = <String, List<String>>{};
    if (!ignoreRange && range != null && range.startsWith('bytes=')) {
      start = int.parse(range.substring('bytes='.length).split('-').first);
      if (start > payload.length) {
        // Range beyond the resource — a real CDN answers 416.
        return ResponseBody.fromBytes(
            Uint8List(0), HttpStatus.requestedRangeNotSatisfiable);
      }
      status = HttpStatus.partialContent; // 206
      headers[HttpHeaders.contentRangeHeader] = [
        'bytes $start-${payload.length - 1}/${payload.length}'
      ];
    }
    final body = Uint8List.fromList(payload.sublist(start));
    headers[HttpHeaders.contentLengthHeader] = ['${body.length}'];
    return ResponseBody.fromBytes(body, status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

/// Serves the payload in two chunks with a test-controlled gate between them,
/// so a test can cancel deterministically mid-transfer.
class _PacedAdapter implements HttpClientAdapter {
  _PacedAdapter(this.payload);

  final List<int> payload;

  /// Held until the test releases it; the tail chunk flows only afterwards.
  final Completer<void> gate = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final half = payload.length ~/ 2;
    Stream<Uint8List> body() async* {
      yield Uint8List.fromList(payload.sublist(0, half));
      await gate.future;
      yield Uint8List.fromList(payload.sublist(half));
    }

    return ResponseBody(body(), HttpStatus.ok, headers: {
      HttpHeaders.contentLengthHeader: ['${payload.length}'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late ModelDownloadService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reckon_model_test');
    service = ModelDownloadService(documentsDirectory: () async => tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  const spec = ReckonModelSpec.qwen25_1_5b;

  File finalFile() => File('${tempDir.path}/${spec.fileName}');

  Future<void> writeBytes(File f, int bytes) async {
    await f.writeAsBytes(Uint8List(bytes));
  }

  test('isDownloaded is false when no file exists', () async {
    expect(await service.isDownloaded(spec), isFalse);
  });

  test(
      'isDownloaded keeps a present model file regardless of the declared '
      'approximate size (regression: must not delete real models)', () async {
    // 2 MB — far below the old 80%-of-780MB (~624 MB) deletion floor that
    // used to nuke correctly-downloaded int4 artifacts. The rename-on-success
    // scheme means a file at the final path is complete by construction.
    await writeBytes(finalFile(), 2 * 1024 * 1024);

    expect(await service.isDownloaded(spec), isTrue);
    expect(finalFile().existsSync(), isTrue,
        reason: 'a present final file must not be deleted');
  });

  test('isDownloaded deletes and rejects a sub-1MB junk file', () async {
    await writeBytes(finalFile(), 1024); // 1 KB — junk

    expect(await service.isDownloaded(spec), isFalse);
    expect(finalFile().existsSync(), isFalse);
  });

  test('delete removes both the final file and any leftover .part', () async {
    await writeBytes(finalFile(), 2 * 1024 * 1024);
    final part = File('${tempDir.path}/${spec.fileName}.part');
    await writeBytes(part, 1024);

    await service.delete(spec);

    expect(finalFile().existsSync(), isFalse);
    expect(part.existsSync(), isFalse);
  });

  // Resume behaviour: a download interrupted (e.g. by the phone sleeping and
  // Android suspending the process) must pick up from the bytes already on
  // disk via an HTTP Range request, not throw them away and restart from zero.
  group('download resumes instead of restarting from zero', () {
    late List<int> payload;
    late ReckonModelSpec testSpec;

    setUp(() {
      payload = List<int>.generate(2 * 1024 * 1024, (i) => i % 251);
      testSpec = ReckonModelSpec(
        id: 'test-model',
        displayName: 'Test',
        fileName: 'test-model.task',
        downloadUrl: 'https://example.test/model',
        approximateSizeBytes: payload.length,
        modelType: 'gemmaIt',
      );
    });

    /// A service whose dio is backed by the in-memory transport above.
    ({ModelDownloadService svc, _FakeAdapter adapter}) build({
      bool ignoreRange = false,
      int? errorStatus,
    }) {
      final adapter = _FakeAdapter(payload,
          ignoreRange: ignoreRange, errorStatus: errorStatus);
      final dio = Dio()..httpClientAdapter = adapter;
      return (
        svc: ModelDownloadService(
            dio: dio, documentsDirectory: () async => tempDir),
        adapter: adapter,
      );
    }

    File partOf() => File('${tempDir.path}/${testSpec.fileName}.part');
    File modelOf() => File('${tempDir.path}/${testSpec.fileName}');

    test('a fresh download (no .part) fetches the whole file with no Range',
        () async {
      final h = build();

      await h.svc.download(testSpec).toList();

      expect(modelOf().existsSync(), isTrue);
      expect(await modelOf().length(), payload.length);
      expect(partOf().existsSync(), isFalse);
      expect(h.adapter.rangeHeaders, [null], reason: 'nothing to resume from');
    });

    test('an existing .part is resumed with a Range request, not restarted',
        () async {
      const have = 1024 * 1024; // 1 MB already transferred
      await partOf().writeAsBytes(payload.sublist(0, have));
      final h = build();

      await h.svc.download(testSpec).toList();

      expect(h.adapter.rangeHeaders, ['bytes=$have-'],
          reason: 'must request only the missing tail');
      expect(modelOf().existsSync(), isTrue);
      expect(await modelOf().readAsBytes(), payload,
          reason: 'resumed file must equal the full payload byte-for-byte');
    });

    test('an oversized .part is discarded and re-downloaded from zero', () async {
      // A corrupt/oversized partial makes the resume Range unsatisfiable (416).
      // Recovery must discard it and download from byte 0 — not loop on 416.
      await partOf().writeAsBytes(Uint8List(payload.length + 1024 * 1024));
      final h = build();

      await h.svc.download(testSpec).toList();

      expect(modelOf().existsSync(), isTrue);
      expect(await modelOf().readAsBytes(), payload,
          reason: 'oversized partial must be recovered from zero');
    });

    test('a failed attempt keeps the partial .part so the next can resume',
        () async {
      const have = 1024 * 1024;
      await partOf().writeAsBytes(payload.sublist(0, have));
      final h = build(errorStatus: 503);

      await expectLater(
          h.svc.download(testSpec).toList(), throwsA(isA<Object>()));

      expect(partOf().existsSync(), isTrue,
          reason: 'progress must survive a failed attempt');
      expect(await partOf().length(), have,
          reason: 'the partial must not be deleted or truncated on error');
    });

    test('cancelling the subscription stops the writer: no promote, .part '
        'kept for resume', () async {
      // Subscription cancellation is the UI's only pause button (dispose and
      // re-download both call _sub.cancel()). It must actually stop the
      // transfer — not leave a detached writer downloading gigabytes and
      // promoting the file behind the user's back.
      final adapter = _PacedAdapter(payload);
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = ModelDownloadService(
          dio: dio, documentsDirectory: () async => tempDir);

      final firstChunk = Completer<void>();
      final sub = svc.download(testSpec).listen((event) {
        if (!firstChunk.isCompleted) firstChunk.complete();
      }, onError: (Object _) {});
      await firstChunk.future; // the transfer is genuinely underway
      await sub.cancel();
      // Release the tail — a writer that survived the cancel would now
      // finish the download and promote the file.
      adapter.gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(modelOf().existsSync(), isFalse,
          reason: 'cancel must stop the transfer before promotion — a '
              'promoted file means the writer ignored the cancel');
      expect(partOf().existsSync(), isTrue,
          reason: 'the partial must be kept so a later attempt can resume');
      expect(await partOf().length(), lessThan(payload.length),
          reason: 'no bytes should be written after the cancel');
    });

    test('a host that ignores Range (200) yields the correct file, not a '
        'corrupt append', () async {
      // Stale junk from a prior attempt against a non-resumable host.
      await partOf().writeAsBytes(List<int>.filled(1024 * 1024, 0xFF));
      final h = build(ignoreRange: true);

      await h.svc.download(testSpec).toList();

      expect(await modelOf().readAsBytes(), payload,
          reason: 'a 200 must overwrite the .part, never append onto stale '
              'bytes');
    });
  });
}
