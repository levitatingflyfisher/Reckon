import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// A section label: the word that names what every number or field under it
/// is, so it has to read. Sentence case, 13 px bold (the ladder's
/// `OhTypography.labelSm`), in the theme's label role, which clears 4.5:1 on
/// Reckon's scaffold and card in all three themes (reckon_contrast_test).
///
/// It stays out of the accent: in the OpenHearth colour language warmth is
/// for the one primary action, and chrome is neutral.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: OhTypography.labelSm(
                  color: OhColorRoles.of(context).textLabel,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
