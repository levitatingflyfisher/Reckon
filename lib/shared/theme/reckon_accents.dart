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
  /// Light-theme primary. Formerly the fork's `hearth500`.
  static const ember500 = Color(0xFFB85C38);

  /// Evening-theme (hearthDark) primary. Formerly the fork's `hearth400`.
  static const ember400 = Color(0xFFD2703F);

  /// Lighter ember tint (formerly the fork's `hearth300`). Kept because it is
  /// part of the same blessed ramp, available for tints/containers.
  static const ember300 = Color(0xFFE49069);

  /// Darker ember shade (formerly the fork's `hearth600`).
  static const ember600 = Color(0xFF9A4A2C);
}
