import 'package:flutter/material.dart';

enum OHButtonStyle { primary, secondary, text }

/// Reckon-specific button adapter — label/icon convenience + optional
/// full-width. Shape, color, and typography come from OhTheme (StadiumBorder
/// pills by default).
class OHButton extends StatelessWidget {
  const OHButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = OHButtonStyle.primary,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final OHButtonStyle style;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        // Flexible + ellipsis so a long label (or large accessibility text
        // scale) on an expanded button can't overflow the Row at narrow
        // widths; harmless in the min-size case where space isn't constrained.
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    switch (style) {
      case OHButtonStyle.primary:
        return ElevatedButton(onPressed: onPressed, child: child);
      case OHButtonStyle.secondary:
        return OutlinedButton(onPressed: onPressed, child: child);
      case OHButtonStyle.text:
        return TextButton(onPressed: onPressed, child: child);
    }
  }
}
