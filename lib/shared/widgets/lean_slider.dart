import 'package:flutter/material.dart';

/// Reckon-specific lean slider — two option labels flanking a 0–100 slider.
/// Slider colors, track height, and thumb size come from OhTheme.sliderTheme.
class LeanSlider extends StatelessWidget {
  const LeanSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.optionA,
    required this.optionB,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String optionA;
  final String optionB;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                optionA,
                style: textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                optionB,
                style: textTheme.labelLarge,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Slider(
          min: 0,
          max: 100,
          value: value,
          onChanged: onChanged,
        ),
        Center(
          child: Text(
            '${value.round()} / 100',
            style: textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
