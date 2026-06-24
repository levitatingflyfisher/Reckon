import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';

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

  const spec = ReckonModelSpec.gemma3_1b;

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
}
