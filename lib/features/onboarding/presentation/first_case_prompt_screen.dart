import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/oh_button.dart';

class FirstCasePromptScreen extends StatelessWidget {
  const FirstCasePromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "What's a decision you're sitting with right now?",
                style: textTheme.displayMedium,
              ),
              const SizedBox(height: 24),
              Text(
                "If you have one in mind, we can open it. If not, we'll "
                'take you to the home screen.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OHButton(
                      label: 'Open a case',
                      onPressed: () => context.go('/intake'),
                      expanded: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OHButton(
                      label: 'Maybe later',
                      style: OHButtonStyle.secondary,
                      onPressed: () => context.go('/'),
                      expanded: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
