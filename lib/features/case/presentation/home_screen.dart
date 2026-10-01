import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../../shared/widgets/oh_card.dart';
import '../data/case_providers.dart';
import '../domain/entities/case.dart';
import '../../../core/theme/theme_preference.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(openCasesStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reckon'),
        actions: [
          OhBarActions(children: [
            // The only door into group voting (ReckonParty), so it carries
            // its word, not just a glyph and a tooltip touch never shows.
            OhBarAction(
              icon: Icons.groups_outlined,
              label: 'Group vote',
              onPressed: () => context.push('/party/create'),
            ),
            const ReckonThemeToggle(),
          ]),
        ],
      ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unfinished backup setup, dismissible (fleet first-run
            // ruling): the journal lives only on this phone until then.
            const BackupSetupReminder(),
            Expanded(
              child: casesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => OhErrorState.fromError(e,
                    stackTrace: st, title: "Couldn’t load your decisions"),
                data: (cases) {
                  if (cases.isEmpty) {
                    // Scrolls so the message survives 320 dp at 3x text; the
                    // bottom inset keeps it clear of the New case button.
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OhWholeWordsText(
                              'No open decisions yet.',
                              style: textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            OhWholeWordsText(
                              'Choose New decision to start your first one.',
                              style: textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CaseTile(case_: cases[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/intake'),
        icon: const Icon(Icons.add),
        // The label stops growing at 2x so the button stays whole on a
        // 320 dp phone at 3x (the FAB widens with its label; it does not
        // ellipsize). The page's own text scales fully.
        label: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 2.0,
          child: const Text('New decision'),
        ),
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.case_});
  final Case case_;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final deadline = case_.deadline;
    final fmt = DateFormat.yMMMd();
    return OHCard(
      onTap: () => context.push('/case/${case_.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(case_.question, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${case_.optionA}  vs  ${case_.optionB}',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          // Wraps, so the date drops under the chip at large text instead
          // of running off a 320 dp screen.
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusChip(status: case_.status),
              if (deadline != null)
                Text('by ${fmt.format(deadline)}', style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = switch (status) {
      CaseStatus.open => 'Open',
      CaseStatus.decided => 'Decided',
      CaseStatus.resolving => 'Resolving',
      CaseStatus.closed => 'Closed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      // The theme's label style, so the chip is set in Nunito like the rest
      // of the chrome (a bare TextStyle fell back to the platform face).
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: colors.onPrimaryContainer),
      ),
    );
  }
}
