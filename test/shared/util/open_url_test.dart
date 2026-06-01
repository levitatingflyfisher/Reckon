import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/shared/util/open_url.dart';

void main() {
  Widget host(void Function(BuildContext) onPressed) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onPressed(context),
              child: const Text('go'),
            ),
          ),
        ),
      );

  testWidgets('shows a SnackBar when the launcher cannot open the url',
      (tester) async {
    await tester.pumpWidget(host(
      (c) => openExternalUrl(c, 'https://x', launcher: (_) async => false),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Could not open link'), findsOneWidget);
  });

  testWidgets('opens the url and shows no SnackBar on success', (tester) async {
    Uri? opened;
    await tester.pumpWidget(host(
      (c) => openExternalUrl(c, 'https://example.org/study', launcher: (u) async {
        opened = u;
        return true;
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    expect(opened, Uri.parse('https://example.org/study'));
    expect(find.text('Could not open link'), findsNothing);
  });
}
