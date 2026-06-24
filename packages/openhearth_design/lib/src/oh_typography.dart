import 'package:flutter/material.dart';

/// OpenHearth type ramp.
///
/// Two families, per the design grammar:
///   * **Lora** (serif) — decision text and display. It's a journal; the
///     things you write and the things you're deciding read as prose.
///   * **Nunito** (sans) — UI chrome: buttons, labels, captions, section heads.
///
/// Font families are bundled by the consuming app; this references them by name.
abstract final class OhTypography {
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
