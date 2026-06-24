import 'package:flutter/material.dart';

/// Thin adapter over [TextField] so app code stays off the raw Material
/// surface. Styling (fill color, border radius, borders, hint color) is
/// inherited from OhTheme's inputDecorationTheme — no overrides here.
class OHTextField extends StatelessWidget {
  const OHTextField({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.maxLines = 1,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? hint;
  final String? label;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}
