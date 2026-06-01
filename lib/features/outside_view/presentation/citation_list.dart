import 'package:flutter/material.dart';

import '../../../shared/util/open_url.dart';
import '../domain/entities/citation.dart';

/// Renders the curated literature citations behind an Outside View.
///
/// Citations are human-curated reference-class sources, shown separately from
/// the model's synthesis and labelled as independent of it. Linked citations
/// open in the system browser; the section is hidden entirely when empty.
class CitationList extends StatelessWidget {
  const CitationList({super.key, required this.citations, this.onOpen});

  final List<Citation> citations;

  /// Opens a citation URL, returning whether it was handled. Injectable so
  /// widget tests can observe taps without the platform launcher; defaults to
  /// the system browser.
  final Future<bool> Function(Uri uri)? onOpen;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sources', style: textTheme.labelLarge),
        const SizedBox(height: 2),
        Text('Curated — independent of the model.',
            style: textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final c in citations) _CitationRow(citation: c, onOpen: onOpen),
      ],
    );
  }
}

class _CitationRow extends StatelessWidget {
  const _CitationRow({required this.citation, this.onOpen});

  final Citation citation;
  final Future<bool> Function(Uri uri)? onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final linked = citation.hasLink;

    final content = ConstrainedBox(
      // Material minimum touch target.
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    citation.title.isEmpty ? citation.url : citation.title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: linked ? colors.primary : null,
                      decoration: linked ? TextDecoration.underline : null,
                    ),
                  ),
                  if (citation.author.isNotEmpty)
                    Text(citation.author, style: textTheme.bodySmall),
                ],
              ),
            ),
            if (linked) ...[
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 16, color: colors.primary),
            ],
          ],
        ),
      ),
    );

    if (!linked) return content;
    return InkWell(
      onTap: () => openExternalUrl(context, citation.url, launcher: onOpen),
      child: content,
    );
  }
}
