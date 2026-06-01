import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:reckon/shared/widgets/oh_card.dart';

import 'visual_golden_helper.dart';

/// A representative OHCard payload: a heading plus a long body that must wrap
/// without overflowing the card padding at narrow widths / large text scale.
Widget _cardSample() {
  return Builder(
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OHCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reference class', style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Most people who weigh a long-tenure career move against a '
                'shorter-horizon one report stable satisfaction within two '
                'years — the base rate favours patience here.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text('Uncertainty: medium', style: textTheme.bodySmall),
            ],
          ),
        ),
      );
    },
  );
}

void main() {
  // OHCard pulls its surface color from the colorScheme, so it looks different
  // in each OhTheme variant — golden each so a theme regression is visible.
  final themes = <String, ThemeData>{
    'light': OhTheme.light(),
    'hearthdark': OhTheme.hearthDark(),
    'night': OhTheme.night(),
  };

  themes.forEach((variant, theme) {
    testWidgets('OHCard golden — $variant theme', (tester) async {
      await goldenAtSizes(
        tester,
        name: 'oh_card_$variant',
        theme: theme,
        // Scroll host: at textScale 3.0 the card body is taller than a phone
        // viewport, so a non-scrolling Scaffold body would itself overflow.
        // The card is the unit under test, not the page chrome.
        home: Scaffold(
          body: SafeArea(child: SingleChildScrollView(child: _cardSample())),
        ),
        sizes: const <String, Size>{
          'phone': Size(360, 800),
          'narrow': Size(320, 800),
        },
        textScales: const <double>[1.0, 3.0],
      );
    });
  });
}
