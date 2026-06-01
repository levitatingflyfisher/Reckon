import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:reckon/shared/widgets/oh_button.dart';

import 'visual_golden_helper.dart';

/// One column showing every [OHButtonStyle] variant in both inline and
/// `expanded: true` form, plus a labelled icon button. This is the widget
/// under the most layout stress (label + optional icon Row), so it is the
/// best place to sweep accessibility text scale for overflow.
Widget _buttonGallery() {
  Widget block(String heading, OHButtonStyle style) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading),
          const SizedBox(height: 6),
          // Wrap (not Row) for the inline pair: at textScale 3.0 two
          // natural-width buttons exceed 320dp, and that demo-layout reflow is
          // not what this golden is testing — the expanded button below is.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OHButton(label: 'Action', onPressed: () {}, style: style),
              OHButton(
                label: 'With icon',
                onPressed: () {},
                style: style,
                icon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: 6),
          OHButton(
            label: 'Full width $heading',
            onPressed: () {},
            style: style,
            expanded: true,
          ),
          const SizedBox(height: 16),
        ],
      );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        block('primary', OHButtonStyle.primary),
        block('secondary', OHButtonStyle.secondary),
        block('text', OHButtonStyle.text),
      ],
    ),
  );
}

void main() {
  testWidgets('OHButton variants responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'oh_button',
      // Render through the real OhTheme so the StadiumBorder pills, button
      // typography and accent colors match production, not bare Material.
      theme: OhTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(child: _buttonGallery()),
        ),
      ),
      sizes: const <String, Size>{
        'phone': Size(360, 800),
        'narrow': Size(320, 800),
      },
      // 1.0 / 3.0 is the accessibility worst case; 320dp/×3 is where a
      // label + icon Row overflows if any child is rigid.
      textScales: const <double>[1.0, 3.0],
    );
  });
}
