import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/forecasters/data/forecaster_providers.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';
import 'package:reckon/features/forecasters/presentation/forecaster_settings_section.dart';

import '../in_memory_fakes.dart';

Forecaster _persona(String id, String name) => Forecaster(
      id: id,
      displayName: name,
      kind: ForecasterKind.persona,
      config: const {'persona': 'A stance.'},
      createdAt: DateTime(2026, 7, 11),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryForecasterRepository repo;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    repo = InMemoryForecasterRepository([
      _persona('persona-base-rate-skeptic', 'Base-rate skeptic'),
      _persona('persona-steelman-advocate', 'Steelman advocate'),
    ]);
  });

  Widget harness() => ProviderScope(
        overrides: [
          forecasterRepositoryProvider.overrideWithValue(repo),
          // Runnability pulls in the model-download stack; irrelevant here.
          runnableForecastersProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ForecastersSection()),
          ),
        ),
      );

  testWidgets('renders the persona roster with enable switches',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Base-rate skeptic'), findsOneWidget);
    expect(find.text('Steelman advocate'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2));
  });

  testWidgets('toggling a switch benches the forecaster (persisted)',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect((await repo.enabled()).map((f) => f.id),
        ['persona-steelman-advocate']);
    // The bench survives the rebuild: the switch renders off.
    final first = tester.widgetList<Switch>(find.byType(Switch)).first;
    expect(first.value, isFalse);
  });

  testWidgets('adds a persona forecaster through the minimal form',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add forecaster'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), "Devil's advocate");
    await tester.enterText(find.widgetWithText(TextField, 'Stance'),
        'Argues against whichever option feels safest.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text("Devil's advocate"), findsOneWidget);
    expect(repo.roster, hasLength(3));
    final added = repo.roster.last;
    expect(added.kind, ForecasterKind.persona);
    expect(added.config['persona'], contains('safest'));
    expect(added.id, startsWith('custom-'));
  });

  testWidgets('deletes a forecaster from its edit form', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Base-rate skeptic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Base-rate skeptic'), findsNothing);
    expect(repo.roster.map((f) => f.id), ['persona-steelman-advocate']);
  });

  testWidgets('BYOK key card: add stores the key, then offers Clear',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, ' sk-ant-test-123 ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Clear'), findsOneWidget);
    expect(
        await const FlutterSecureStorage()
            .read(key: 'reckon.anthropic_api_key'),
        'sk-ant-test-123'); // trimmed

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Add key'), findsOneWidget);
  });
}
