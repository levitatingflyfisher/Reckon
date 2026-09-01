import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';

class AuthTierScreen extends StatelessWidget {
  const AuthTierScreen({super.key});

  Future<void> _selectGhost(BuildContext context) async {
    await markOnboardingComplete();
    if (context.mounted) context.go('/onboarding/model');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: OhPage(
        padding: EdgeInsets.zero,
        child: SafeArea(
          // Content scrolls; the primary action is pinned below it so it stays
          // on screen at large text sizes on small phones (360 dp at 1.3).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text('How do you want to use Reckon?',
                          style: textTheme.displayMedium),
                      const SizedBox(height: 12),
                      Text(
                        'You can change this later, but your privacy posture is a '
                        'choice, not a default we nudge you toward.',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      OHCard(
                        onTap: () => _selectGhost(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Just me, privately', style: textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              'Your decisions stay on your device. No account. No '
                              'recovery. No community. If you lose the device, you '
                              'lose your record.',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OHCard(
                        onTap: null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Private but recoverable',
                                style: textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              'Anonymous account recoverable with an email. Full '
                              'features. Coming soon.',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OHCard(
                        onTap: null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Simple login', style: textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              'Standard account. Everything works. Coming soon.',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: OHButton(
                  label: 'Continue privately',
                  expanded: true,
                  onPressed: () => _selectGhost(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
