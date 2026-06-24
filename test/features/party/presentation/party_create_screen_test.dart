import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/presentation/party_create_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PartyCreateScreen()),
      ),
    );
  }

  testWidgets('starts with a title field and two option fields', (t) async {
    await pump(t);
    // title + 2 options
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Start voting'), findsOneWidget);
  });

  testWidgets('Add option appends a field, up to the max', (t) async {
    await pump(t);
    await t.tap(find.text('Add option'));
    await t.pump();
    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('Start voting is disabled until title + two options filled',
      (t) async {
    await pump(t);

    ElevatedButton button() => t.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start voting'));

    expect(button().onPressed, isNull); // nothing entered yet

    await t.enterText(find.byType(TextField).at(0), 'Where to eat?');
    await t.enterText(find.byType(TextField).at(1), 'Tacos');
    await t.enterText(find.byType(TextField).at(2), 'Sushi');
    await t.pump();

    expect(button().onPressed, isNotNull);
  });
}
