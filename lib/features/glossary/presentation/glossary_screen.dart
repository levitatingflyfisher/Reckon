import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_card.dart';
import '../data/glossary_providers.dart';

class GlossaryScreen extends ConsumerWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final entries = ref.watch(glossaryEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Techniques')),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
                      style: textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Lora',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
