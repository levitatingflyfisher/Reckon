import 'package:flutter/material.dart';

/// Reckon's blessed design tokens (everything but the ember accents, which
/// live in `reckon_accents.dart`).
///
/// These values came from Reckon's former in-repo fork of
/// `openhearth_design`. When the fork was retired it turned out **every**
/// token had diverged from canonical — the linen ramp, sage, both dark
/// surface sets, the radii, and the type ladder, not just the terracotta
/// accents. Per the de-fork decision the shipped values are blessed as
/// Reckon's identity and kept here verbatim: the app must not change
/// appearance by a single pixel (golden sweeps under `test/visual/` are the
/// proof). Canonical tokens (different values) live in the shared
/// `openhearth_design` package; adopting any of them is a deliberate visual
/// change for a future pass, not a refactor.
abstract final class ReckonPalette {
  // --- Linen (warm neutral ramp) ---
  static const linen50 = Color(0xFFFBF7F0);
  static const linen100 = Color(0xFFF4EEE2);
  static const linen200 = Color(0xFFEAE1D1);
  static const linen300 = Color(0xFFD9CDB7);
  static const linen400 = Color(0xFFB8AB91);
  static const linen500 = Color(0xFF8C8169); // secondary text on light
  static const linen600 = Color(0xFF6B6353);
  static const linen700 = Color(0xFF4E483D);
  static const linen800 = Color(0xFF332F28);
  static const linen900 = Color(0xFF1E1B16);

  // --- Sage (night accent) ---
  static const sage300 = Color(0xFFAEBDA0);
  static const sage400 = Color(0xFF8FA07E);
  static const sage500 = Color(0xFF748563);

  // --- hearthDark surfaces (warm brown-black) ---
  static const hearthDarkBg = Color(0xFF221C18);
  static const hearthDarkSurface = Color(0xFF2C2521);
  static const hearthDarkSurfaceHigh = Color(0xFF392F2A);

  // --- night surfaces (neutral high-contrast dark) ---
  static const nightBg = Color(0xFF14161A);
  static const nightSurface = Color(0xFF1C1F24);
  static const nightSurfaceHigh = Color(0xFF262A30);
  static const nightText = Color(0xFFE6E8EA);
}

/// Corner-radius tokens. [lg] (16) is the default card/input radius.
/// Blessed fork values — canonical `OhRadii` uses a smaller scale (lg = 12).
abstract final class ReckonRadii {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Reckon's type ramp (blessed fork ladder — distinct from canonical
/// `OhTypography`'s 48/36/30 role ladder).
///
/// Two families, per the design grammar:
///   * **Lora** (serif) — decision text and display. It's a journal; the
///     things you write and the things you're deciding read as prose.
///   * **Nunito** (sans) — UI chrome: buttons, labels, captions, section heads.
///
/// Font files are bundled by this app (`pubspec.yaml` → `flutter.fonts`);
/// these styles reference the families by name.
abstract final class ReckonTypography {
  static const serif = 'Lora';
  static const sans = 'Nunito';

  /// Small-caps section label (used by `SectionHeader`). Sans, tracked out.
  static TextStyle labelSm({Color? color}) => TextStyle(
        fontFamily: sans,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        height: 1.2,
        color: color,
      );

  /// The full [TextTheme]. Serif owns display/headline/title and the large
  /// body ramp (journal text); sans owns the medium/small body and all labels.
  static TextTheme textTheme(Color onSurface) {
    const t = TextTheme(
      displayLarge: TextStyle(
          fontFamily: serif,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 1.12),
      displayMedium: TextStyle(
          fontFamily: serif,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.15),
      displaySmall: TextStyle(
          fontFamily: serif,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          height: 1.2),
      headlineMedium: TextStyle(
          fontFamily: serif,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.25),
      headlineSmall: TextStyle(
          fontFamily: serif,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3),
      titleLarge: TextStyle(
          fontFamily: serif,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3),
      titleMedium: TextStyle(
          fontFamily: sans,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35),
      titleSmall: TextStyle(
          fontFamily: sans,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35),
      // Journal/decision body reads as serif prose.
      bodyLarge: TextStyle(
          fontFamily: serif,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.5),
      bodyMedium: TextStyle(
          fontFamily: sans,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45),
      bodySmall: TextStyle(
          fontFamily: sans,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4),
      labelLarge: TextStyle(
          fontFamily: sans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.2),
      labelMedium: TextStyle(
          fontFamily: sans,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2),
      labelSmall: TextStyle(
          fontFamily: sans,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          height: 1.2),
    );
    return t.apply(bodyColor: onSurface, displayColor: onSurface);
  }
}
