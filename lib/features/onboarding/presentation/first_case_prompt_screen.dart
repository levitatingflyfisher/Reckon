import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/oh_button.dart';

class FirstCasePromptScreen extends StatelessWidget {
  const FirstCasePromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: OhPage(
        padding: EdgeInsets.zero,
        child: SafeArea(
          // Scrolls when the question outgrows the screen (large text on a
          // small phone); the two actions are pinned below and stacked, so
          // neither label is squeezed into half the width.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 40)
                            .clamp(0, double.infinity),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "What’s a decision you’re sitting with right now?",
                            style: textTheme.displayMedium,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "If you have one in mind, we can open it. If not, "
                            "we’ll take you to the home screen.",
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OHButton(
                      key: const Key('first-case-open'),
                      label: 'Start a decision',
                      onPressed: () => context.go('/intake'),
                      expanded: true,
                    ),
                    const SizedBox(height: 12),
                    OHButton(
                      label: 'Maybe later',
                      style: OHButtonStyle.secondary,
                      onPressed: () => context.go('/'),
                      expanded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
