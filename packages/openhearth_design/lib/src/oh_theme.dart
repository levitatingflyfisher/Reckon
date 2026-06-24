import 'package:flutter/material.dart';

import 'oh_colors.dart';
import 'oh_radii.dart';
import 'oh_typography.dart';

/// The three OpenHearth themes. A theme is a user-owned preference — the app
/// never flips it based on system dark-mode (see Reckon's `ThemePreference`).
///
///   * [light]      — hearth terracotta on linen. Daytime default.
///   * [hearthDark] — warm brown-black, hearth-family. Evening.
///   * [night]      — neutral high-contrast dark, sage accent. Late night.
abstract final class OhTheme {
  /// Hearth terracotta on linen.
  static ThemeData light() => _build(
        _scheme(
          brightness: Brightness.light,
          seed: OhColors.hearth500,
          primary: OhColors.hearth500,
          onPrimary: OhColors.linen50,
          surface: OhColors.linen50,
          surfaceHighest: OhColors.linen100,
          onSurface: OhColors.linen900,
          onSurfaceVariant: OhColors.linen600,
          outline: OhColors.linen300,
        ),
      );

  /// Warm brown-black, still hearth-family.
  static ThemeData hearthDark() => _build(
        _scheme(
          brightness: Brightness.dark,
          seed: OhColors.hearth400,
          primary: OhColors.hearth400,
          onPrimary: OhColors.linen900,
          surface: OhColors.hearthDarkBg,
          surfaceHighest: OhColors.hearthDarkSurfaceHigh,
          onSurface: OhColors.linen100,
          onSurfaceVariant: OhColors.linen400,
          outline: OhColors.linen700,
        ),
      );

  /// Neutral high-contrast dark with sage accent.
  static ThemeData night() => _build(
        _scheme(
          brightness: Brightness.dark,
          seed: OhColors.sage400,
          primary: OhColors.sage400,
          onPrimary: OhColors.nightBg,
          surface: OhColors.nightBg,
          surfaceHighest: OhColors.nightSurfaceHigh,
          onSurface: OhColors.nightText,
          onSurfaceVariant: const Color(0xFFA7ACB3),
          outline: const Color(0xFF3A3F47),
        ),
      );

  /// Build a complete [ColorScheme] from explicit tokens. We seed for full M3
  /// slot coverage, then override the slots the design actually pins.
  static ColorScheme _scheme({
    required Brightness brightness,
    required Color seed,
    required Color primary,
    required Color onPrimary,
    required Color surface,
    required Color surfaceHighest,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
  }) {
    final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return base.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      surface: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow:
          Color.alphaBlend(onSurface.withValues(alpha: 0.02), surface),
      surfaceContainer:
          Color.alphaBlend(onSurface.withValues(alpha: 0.04), surface),
      surfaceContainerHigh:
          Color.alphaBlend(onSurface.withValues(alpha: 0.06), surface),
      surfaceContainerHighest: surfaceHighest,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.5),
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final text = OhTypography.textTheme(scheme.onSurface);
    const pill = RoundedRectangleBorder(borderRadius: OhRadii.pill);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 52),
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: scheme.outline),
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          shape: pill,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: OhRadii.lg,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: OhRadii.lg,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: OhRadii.lg,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: OhRadii.lg),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: text.labelMedium,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: OhRadii.sm),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: OhRadii.md),
      ),
    );
  }
}
