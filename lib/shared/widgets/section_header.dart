import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// Small-caps section label. In the OpenHearth grammar, hearth is reserved
/// for interactive affordances — section labels use the secondary-text
/// ramp instead.
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
            child: Text(
              label.toUpperCase(),
              style: OhTypography.labelSm(color: OhColors.linen500),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
