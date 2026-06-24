import 'package:flutter/widgets.dart';

/// OpenHearth palette.
///
/// Three families:
///   * **linen** — warm paper neutrals, the background/text ramp.
///   * **hearth** — terracotta, the interactive accent (light + hearthDark).
///   * **sage** — muted green, the night-theme accent.
///
/// The grammar: hearth is reserved for interactive affordances; static text
/// uses the linen ramp (e.g. [linen500] for secondary/section labels).
abstract final class OhColors {
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

  // --- Hearth (terracotta accent) ---
  static const hearth300 = Color(0xFFE49069);
  static const hearth400 = Color(0xFFD2703F);
  static const hearth500 = Color(0xFFB85C38); // primary (light)
  static const hearth600 = Color(0xFF9A4A2C);

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
