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

/// Every model is on disk; records deletes instead of touching files.
class _AllDownloaded extends ModelDownloadService {
  final deleted = <String>[];

  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async =>
      !deleted.contains(spec.id);

  @override
  Future<void> delete(ReckonModelSpec spec) async => deleted.add(spec.id);
}

/// Deleting a model file is the one delete Reckon keeps asking about (fleet
/// ruling, Peckish precedent): it throws away a download of a gigabyte or
/// more that no Undo can hand back without re-fetching it. The question
/// names the act and carries the urgency icon.
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  late _AllDownloaded svc;

  Widget harness() => ProviderScope(
        overrides: [
          onDeviceModelSupportedProvider.overrideWithValue(true),
          modelDownloadServiceProvider.overrideWithValue(svc),
          forecasterRepositoryProvider
              .overrideWithValue(InMemoryForecasterRepository(const [])),
          runnableForecastersProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      );

  Future<void> tapFirstDelete(WidgetTester tester) async {
    final delete = find.widgetWithText(TextButton, 'Delete').first;
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
  }

  testWidgets('asks first, with a button that names the act', (tester) async {
    svc = _AllDownloaded();
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tapFirstDelete(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    // FilledButton.icon is a private subtype, so match by subtype.
    final confirm = find.ancestor(
        of: find.text('Delete model'),
        matching: find.bySubtype<FilledButton>());
    expect(confirm, findsOneWidget);
    // Danger never rests on colour alone.
    expect(
        find.descendant(
            of: confirm, matching: find.byIcon(Icons.report_outlined)),
        findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(svc.deleted, isEmpty);
  });

  testWidgets('confirming deletes the file', (tester) async {
    svc = _AllDownloaded();
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tapFirstDelete(tester);
    await tester.tap(find.text('Delete model'));
    await tester.pumpAndSettle();

    expect(svc.deleted, hasLength(1));
  });
}
