import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/util/open_url.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/glossary_providers.dart';
import '../domain/entities/glossary_entry.dart';

class GlossaryDetailScreen extends ConsumerWidget {
  const GlossaryDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final entry = ref.watch(glossaryEntryProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Technique')),
      body: entry.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (e) {
          if (e == null) return const Center(child: Text('Not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(e.title, style: textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                e.oneLine,
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: 'Lora',
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SectionHeader(label: 'THE IDEA'),
              OHCard(child: Text(e.paragraph, style: textTheme.bodyLarge)),
              const SectionHeader(label: 'EXAMPLE'),
              OHCard(child: Text(e.example, style: textTheme.bodyLarge)),
              if (e.sources.isNotEmpty) ...[
                const SectionHeader(label: 'FURTHER READING'),
                OHCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < e.sources.length; i++) ...[
                        _CitationTile(citation: e.sources[i]),
                        if (i < e.sources.length - 1)
                          const Divider(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CitationTile extends StatelessWidget {
  const _CitationTile({required this.citation});
  final Citation citation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasLink = citation.url != null && citation.url!.isNotEmpty;
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: hasLink ? () => openExternalUrl(context, citation.url!) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${citation.authors} (${citation.year})',
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(citation.title, style: textTheme.bodyMedium),
            if (citation.venue != null) ...[
              const SizedBox(height: 2),
              Text(
                citation.venue!,
                style:
                    textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            if (hasLink) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.open_in_new, size: 14, color: primary),
                  const SizedBox(width: 4),
                  Text('Open',
                      style: textTheme.bodySmall?.copyWith(color: primary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
