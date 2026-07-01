import 'package:flutter/material.dart';

import 'reckon_accents.dart';
import 'reckon_tokens.dart';

/// The three Reckon themes. A theme is a user-owned preference — the app
/// never flips it based on system dark-mode (see `ThemePreference`).
///
///   * [light]      — ember terracotta on linen. Daytime default.
///   * [hearthDark] — warm brown-black, ember accent. Evening.
///   * [night]      — neutral high-contrast dark, sage accent. Late night.
///
/// ## Why this is app code, not the shared package
///
/// This construction is Reckon's blessed identity, carried over verbatim from
/// the retired in-repo `openhearth_design` fork (de-fork decision, fleet spec
/// §8). The canonical `openhearth_design` package builds its themes
/// differently in nearly every respect (color scheme slots, type ladder,
/// component themes, radii), so reproducing this exact rendering through
/// `OhTheme.*(appAccent: …)` + `copyWith` would mean re-implementing
/// `ThemeData`'s internals. Instead the construction lives here, byte-for-byte
/// equal to what shipped; the golden sweeps in `test/visual/` pin it.
/// Converging on the canonical builders is a deliberate future visual change,
/// not a refactor.
abstract final class ReckonTheme {
  /// Ember terracotta on linen.
  static ThemeData light() => _build(
        _scheme(
          brightness: Brightness.light,
          seed: ReckonAccents.ember500,
          primary: ReckonAccents.ember500,
          onPrimary: ReckonPalette.linen50,
          surface: ReckonPalette.linen50,
          surfaceHighest: ReckonPalette.linen100,
          onSurface: ReckonPalette.linen900,
          onSurfaceVariant: ReckonPalette.linen600,
          outline: ReckonPalette.linen300,
        ),
      );

  /// Warm brown-black, still ember-family.
  static ThemeData hearthDark() => _build(
        _scheme(
          brightness: Brightness.dark,
          seed: ReckonAccents.ember400,
          primary: ReckonAccents.ember400,
          onPrimary: ReckonPalette.linen900,
          surface: ReckonPalette.hearthDarkBg,
          surfaceHighest: ReckonPalette.hearthDarkSurfaceHigh,
          onSurface: ReckonPalette.linen100,
          onSurfaceVariant: ReckonPalette.linen400,
          outline: ReckonPalette.linen700,
        ),
      );

  /// Neutral high-contrast dark with sage accent.
  static ThemeData night() => _build(
        _scheme(
          brightness: Brightness.dark,
          seed: ReckonPalette.sage400,
          primary: ReckonPalette.sage400,
          onPrimary: ReckonPalette.nightBg,
          surface: ReckonPalette.nightBg,
          surfaceHighest: ReckonPalette.nightSurfaceHigh,
          onSurface: ReckonPalette.nightText,
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
    final text = ReckonTypography.textTheme(scheme.onSurface);
    const pill = RoundedRectangleBorder(borderRadius: ReckonRadii.pill);

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
          borderRadius: ReckonRadii.lg,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: ReckonRadii.lg,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ReckonRadii.lg,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: ReckonRadii.lg),
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
        shape: const RoundedRectangleBorder(borderRadius: ReckonRadii.sm),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: ReckonRadii.md),
      ),
    );
  }
}
