/// OpenHearth design system (in-repo reconstruction).
///
/// Public surface consumed by Reckon:
///   * [OhTheme.light] / [OhTheme.hearthDark] / [OhTheme.night] — full ThemeData
///   * [OhColors] — hearth-on-linen palette ramps
///   * [OhRadii] — corner-radius tokens
///   * [OhTypography] — Lora (serif) + Nunito (sans) type ramp
///
/// This is a faithful reconstruction of the shared `../ohStyle/openhearth_design`
/// package, which is not vendored into this repo. Tokens were rebuilt from the
/// documented design grammar (hearth terracotta on linen; sage night accent;
/// serif for decision text, sans for UI chrome). If the canonical package is
/// later brought in-tree, this can be swapped back out — the import path and
/// public API are kept identical on purpose.
library openhearth_design;

export 'src/oh_colors.dart';
export 'src/oh_radii.dart';
export 'src/oh_typography.dart';
export 'src/oh_theme.dart';
