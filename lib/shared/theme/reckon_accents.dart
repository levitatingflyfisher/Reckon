import 'dart:ui';

/// Reckon's blessed accent hues — its visual identity.
///
/// History: Reckon shipped with an in-repo "reconstruction" of the shared
/// `openhearth_design` package whose terracotta values had silently diverged
/// from the canonical `hearth500` / `hearth400` (values deliberately not
/// restated here — C1 forbids retyped token hex, even in comments). The
/// de-fork decision (fleet spec §8) killed the fork and **blessed the
/// diverged hues as Reckon's identity** — so they are named for Reckon now
/// (*ember*), not for the shared hearth ramp they no longer belong to.
abstract final class ReckonAccents {
  /// Light-theme primary. Formerly the fork's `hearth500` (#B85C38, which
  /// gave button labels and accent text only 4.25:1). Darkened the least
  /// OKLCH lightness (-0.032, same hue and chroma) that clears 4.5:1 on
  /// linen50 and linen100 (fleet contrast floor; reckon_contrast_test).
  static const ember500 = Color(0xFFAD522E);

  /// Evening-theme (hearthDark) primary. Formerly the fork's `hearth400`
  /// (#D2703F, 3.80:1 as text on the evening card). Lightened the least
  /// OKLCH lightness (+0.044, same hue and chroma) that clears 4.5:1 on the
  /// evening ground and card, and under its dark button labels.
  static const ember400 = Color(0xFFE17E4D);

  /// Lighter ember tint (formerly the fork's `hearth300`). Kept because it is
  /// part of the same blessed ramp, available for tints/containers.
  static const ember300 = Color(0xFFE49069);

  /// Darker ember shade (formerly the fork's `hearth600`).
  static const ember600 = Color(0xFF9A4A2C);
}
