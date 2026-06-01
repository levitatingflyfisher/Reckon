import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

class OHCard extends StatelessWidget {
  const OHCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: OhRadii.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: OhRadii.lg,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
