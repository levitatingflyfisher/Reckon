import 'package:flutter/material.dart';

enum OHButtonStyle { primary, secondary, text }

/// Reckon-specific button adapter — label/icon convenience + optional
/// full-width. Shape, color, and typography come from ReckonTheme (StadiumBorder
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
        // Flexible so a long label can't overflow the Row at narrow widths.
        // A full-width button wraps (up to three lines) rather than
        // ellipsizing: at 320 dp and 3x text "I’ll live with it for a
        // while" was cut to "I’ll live wi…", and a button must say what it
        // does. An inline button stays one line (it sits in a row).
        Flexible(
          child: Text(
            label,
            maxLines: expanded ? 3 : 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    // Button labels stop growing at 2x (the fleet's bar-label precedent):
    // at 3x a full-width pill three lines tall pushes its words into the
    // rounded ends. The page's own text still scales fully.
    final scaled = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 2.0,
      child: child,
    );

    switch (style) {
      case OHButtonStyle.primary:
        return ElevatedButton(onPressed: onPressed, child: scaled);
      case OHButtonStyle.secondary:
        return OutlinedButton(onPressed: onPressed, child: scaled);
      case OHButtonStyle.text:
        return TextButton(onPressed: onPressed, child: scaled);
    }
  }
}
