import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/features/case/presentation/intake_screen.dart';

/// Fake that reports which model ids are present on disk, without touching
/// path_provider or the real filesystem.
class _FakeDownloadService extends ModelDownloadService {
  _FakeDownloadService(this._downloaded);

  final Set<String> _downloaded;

  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async =>
      _downloaded.contains(spec.id);
}

void main() {
  const opener = "What's the decision you're trying to make?";

  Widget harness({
    required String? selectedId,
    required Set<String> downloadedIds,
  }) {
    return ProviderScope(
      overrides: [
        // FutureProvider — its value is null/loading on the first synchronous
        // read, which is exactly the race the intake gate must survive.
        selectedModelIdProvider.overrideWith((ref) async => selectedId),
        modelDownloadServiceProvider
            .overrideWithValue(_FakeDownloadService(downloadedIds)),
      ],
      child: const MaterialApp(home: IntakeScreen()),
    );
  }

  testWidgets(
      'reaches the opening question when the SELECTED non-default model is '
      'downloaded but the default model is not', (tester) async {
    await tester.pumpWidget(harness(
      selectedId: ReckonModelSpec.qwen25_1_5b.id,
      downloadedIds: {ReckonModelSpec.qwen25_1_5b.id},
    ));
    await tester.pumpAndSettle();

    expect(find.text(opener), findsOneWidget);
    expect(find.textContaining('needs an on-device model'), findsNothing);
  });

  testWidgets(
      'reaches the opening question for the default model when no selection '
      'has been persisted', (tester) async {
    await tester.pumpWidget(harness(
      selectedId: null,
      downloadedIds: {ReckonModelSpec.gemma3_1b.id},
    ));
    await tester.pumpAndSettle();

    expect(find.text(opener), findsOneWidget);
  });
}
