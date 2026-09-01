import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_card.dart';
import '../data/glossary_providers.dart';
import '../../../shared/theme/reckon_tokens.dart';
import '../../../core/theme/theme_preference.dart';

class GlossaryScreen extends ConsumerWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final entries = ref.watch(glossaryEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: const [
          OhBarActions(children: [ReckonThemeToggle()]),
        ],
      ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => OhErrorState.fromError(e,
              stackTrace: st, title: "Couldn’t load Learn"),
          data: (list) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final entry = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OHCard(
                  onTap: () => context.push('/glossary/${entry.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        entry.oneLine,
                        style: ReckonTypography.serifItalic(textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
