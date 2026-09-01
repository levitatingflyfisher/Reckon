import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/app/startup_failure.dart';

/// Startup used to print 'Startup error: <exception>' as the whole screen.
/// The fleet error ruling puts a plain sentence first and the exception
/// behind Details.
void main() {
  testWidgets('a startup failure is a sentence, with the exception behind '
      'Details', (tester) async {
    await tester.pumpWidget(
        StartupFailure(error: StateError('database is locked')));
    await tester.pumpAndSettle();

    expect(find.textContaining("Reckon couldn’t start"), findsOneWidget);
    expect(find.textContaining('database is locked'), findsNothing);

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('database is locked'), findsOneWidget);
  });
}
