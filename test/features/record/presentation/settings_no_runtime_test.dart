import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/features/forecasters/data/forecaster_providers.dart';
import 'package:reckon/features/record/presentation/settings_screen.dart';

import '../../forecasters/in_memory_fakes.dart';

class _NothingDownloaded extends ModelDownloadService {
  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async => false;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Widget harness({required bool runtime}) => ProviderScope(
        overrides: [
          onDeviceModelSupportedProvider.overrideWithValue(runtime),
          modelDownloadServiceProvider.overrideWithValue(_NothingDownloaded()),
          forecasterRepositoryProvider
              .overrideWithValue(InMemoryForecasterRepository(const [])),
          runnableForecastersProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      );

  testWidgets('with a runtime, Settings offers the model downloads',
      (tester) async {
    await tester.pumpWidget(harness(runtime: true));
    await tester.pumpAndSettle();
    expect(find.text(ReckonModelSpec.availableModels.first.displayName),
        findsOneWidget);
  });

  testWidgets(
      'with no on-device runtime (web), Settings offers no model download',
      (tester) async {
    await tester.pumpWidget(harness(runtime: false));
    await tester.pumpAndSettle();
    for (final spec in ReckonModelSpec.availableModels) {
      expect(find.text(spec.displayName), findsNothing);
    }
    expect(find.widgetWithText(ElevatedButton, 'Download'), findsNothing);
    expect(find.textContaining("can’t run"), findsOneWidget);
  });
}
