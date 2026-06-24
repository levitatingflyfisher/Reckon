import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';
import 'package:reckon/features/outside_view/presentation/citation_list.dart';

void main() {
  const linked = Citation(
    author: 'BLS',
    title: 'Employee Tenure in 2024',
    url: 'https://www.bls.gov/tenure',
  );
  const unlinked = Citation(author: 'Anon', title: 'Unlinked study', url: '');

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders a Sources header and each citation', (tester) async {
    await tester.pumpWidget(host(
      const CitationList(citations: [linked, unlinked]),
    ));

    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('Employee Tenure in 2024'), findsOneWidget);
    expect(find.text('Unlinked study'), findsOneWidget);
    expect(find.textContaining('BLS'), findsOneWidget);
  });

  testWidgets('tapping a linked citation opens its URL', (tester) async {
    Uri? opened;
    await tester.pumpWidget(host(
      CitationList(
        citations: const [linked],
        onOpen: (uri) async {
          opened = uri;
          return true;
        },
      ),
    ));

    await tester.tap(find.text('Employee Tenure in 2024'));
    await tester.pump();

    expect(opened, Uri.parse('https://www.bls.gov/tenure'));
  });

  testWidgets('shows feedback when a link cannot be opened', (tester) async {
    await tester.pumpWidget(host(
      CitationList(
        citations: const [linked],
        onOpen: (_) async => false,
      ),
    ));

    await tester.tap(find.text('Employee Tenure in 2024'));
    await tester.pump(); // let the async tap handler run
    await tester.pump(); // surface the SnackBar

    expect(find.text('Could not open link'), findsOneWidget);
  });

  testWidgets('linked citation meets the 48dp minimum tap target',
      (tester) async {
    await tester.pumpWidget(host(const CitationList(citations: [linked])));
    final size = tester.getSize(find.byType(InkWell));
    expect(size.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('renders nothing when there are no citations', (tester) async {
    await tester.pumpWidget(host(const CitationList(citations: [])));
    expect(find.text('Sources'), findsNothing);
  });
}
