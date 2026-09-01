import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';
import 'package:reckon/shared/widgets/section_header.dart';

/// Reckon keeps its own grounds (linen, warm brown-black, neutral night), so
/// the package's contrast test, measured on canonical grounds, says nothing
/// about them. This measures the colour roles Reckon attaches on Reckon's own
/// scaffold and card, in all three themes.
double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

final _themes = <String, ThemeData>{
  'light': ReckonTheme.light(),
  'hearthDark': ReckonTheme.hearthDark(),
  'night': ReckonTheme.night(),
};

void main() {
  // test/fleet_conformance_test.dart records these as C12's accentColors,
  // because C12 cannot resolve ReckonTheme's helper-argument seeds. If a
  // primary changes, this fails and the recorded accent must follow.
  test('the recorded C12 accents are the rendered primaries', () {
    expect(ReckonTheme.light().colorScheme.primary, const Color(0xFFAD522E));
    expect(
        ReckonTheme.hearthDark().colorScheme.primary, const Color(0xFFE17E4D));
    expect(ReckonTheme.night().colorScheme.primary, const Color(0xFF8FA07E));
  });

  for (final MapEntry(key: name, value: theme) in _themes.entries) {
    group(name, () {
      final scheme = theme.colorScheme;
      final grounds = {
        'scaffold': theme.scaffoldBackgroundColor,
        'card': scheme.surfaceContainerHighest,
      };

      test('attaches OhColorRoles whose warmth is the Reckon accent', () {
        final roles = theme.extension<OhColorRoles>();
        expect(roles, isNotNull);
        expect(roles!.warmth, scheme.primary);
      });

      test('error colours are the urgency roles', () {
        final roles = theme.extension<OhColorRoles>()!;
        expect(scheme.error, roles.urgency);
        expect(scheme.onError, roles.onUrgency);
        expect(scheme.errorContainer, roles.urgencySurface);
      });

      test('text roles clear 4.5:1 on scaffold and card', () {
        final roles = theme.extension<OhColorRoles>()!;
        final text = {
          'onSurface': scheme.onSurface,
          'onSurfaceVariant': scheme.onSurfaceVariant,
          'textPrimary': roles.textPrimary,
          'textSecondary': roles.textSecondary,
          'textLabel': roles.textLabel,
          'urgency': roles.urgency,
          'warningText': roles.warningText,
          'success': roles.success,
          'attention': roles.attention,
        };
        text.forEach((role, fg) {
          grounds.forEach((ground, bg) {
            expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5),
                reason: '$role on $ground');
          });
        });
      });

      // Operator ruling (fleet contrast floor): the accent is text on
      // every filled button and every text button, so it clears 4.5:1 both
      // ways. The ember hues were moved the least lightness needed.
      test('the accent clears 4.5:1 as text and under button labels', () {
        grounds.forEach((ground, bg) {
          expect(_ratio(scheme.primary, bg), greaterThanOrEqualTo(4.5),
              reason: 'primary as text on $ground');
        });
        expect(_ratio(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
            reason: 'button label on primary');
      });

      test('mark roles clear 3:1 on scaffold and card', () {
        final roles = theme.extension<OhColorRoles>()!;
        final marks = {
          'icon': roles.icon,
          'warningIcon': roles.warningIcon,
          'controlBorder': roles.controlBorder,
        };
        marks.forEach((role, fg) {
          grounds.forEach((ground, bg) {
            expect(_ratio(fg, bg), greaterThanOrEqualTo(3.0),
                reason: '$role on $ground');
          });
        });
      });

      // Bar commands paint in the bar's icon colour (openhearth_design
      // 0.8+). Measure the rendered word and glyph of an OhBarAction and the
      // theme toggle on Reckon's own bar.
      testWidgets('bar words and glyphs clear 4.5:1 on the bar',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Reckon'), actions: [
              OhBarActions(children: [
                OhBarAction(
                    icon: Icons.groups_outlined,
                    label: 'Group vote',
                    onPressed: () {}),
                OhThemeToggle(
                    value: OhThemeModePreference.system, onChanged: (_) {}),
              ]),
            ]),
          ),
        ));
        final material = tester.widget<Material>(find
            .descendant(of: find.byType(AppBar), matching: find.byType(Material))
            .first);
        final bar = Color.alphaBlend(material.color ?? Colors.transparent,
            theme.scaffoldBackgroundColor);
        Color colorOf(Finder f) => tester
            .widget<RichText>(
                find.descendant(of: f, matching: find.byType(RichText)).first)
            .text
            .style!
            .color!;
        for (final (what, finder) in [
          ('word "Group vote"', find.text('Group vote')),
          ('word "Auto"', find.text('Auto')),
          ('glyph', find.byIcon(Icons.groups_outlined)),
        ]) {
          expect(_ratio(colorOf(finder), bar), greaterThanOrEqualTo(4.5),
              reason: '$name bar $what');
        }
      });

      testWidgets('SectionHeader reads: 13 px or more, 4.5:1 on both grounds',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: const Scaffold(body: SectionHeader(label: 'Clarity score')),
        ));
        final text = tester.widget<Text>(find.text('Clarity score'));
        final style = DefaultTextStyle.of(tester.element(find.text('Clarity score')))
            .style
            .merge(text.style);
        expect(style.fontSize, greaterThanOrEqualTo(13));
        grounds.forEach((ground, bg) {
          expect(_ratio(style.color!, bg), greaterThanOrEqualTo(4.5),
              reason: 'SectionHeader on $ground');
        });
      });
    });
  }
}
