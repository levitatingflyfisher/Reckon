import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/llm/hf_token.dart';
import '../../../core/llm/llm_providers.dart';
import '../../../core/llm/model_spec.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../export/data/export_providers.dart';
import '../../export/domain/formatters.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final selected = ref.watch(activeModelSpecProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('On-device model', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Pick one. The active model runs all of Reckon\'s on-device '
            'reasoning. Changing the selection takes effect the next time '
            'the model is invoked.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final spec in ReckonModelSpec.availableModels)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModelCard(
                spec: spec,
                isSelected: spec.id == selected.id,
              ),
            ),
          const _HfTokenTile(),
          const SizedBox(height: 12),
          Text('Appearance', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          const _ThemePicker(),
          const SizedBox(height: 24),
          Text('Your data', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          const _ExportCard(),
          const SizedBox(height: 24),
          const ListTile(
            title: Text('Auth tier'),
            subtitle: Text('Ghost (local only)'),
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('Reckon — Phase 1 build'),
          ),
        ],
      ),
    );
  }

}

/// Lets the user clear a stored HuggingFace token. Hidden when none is set.
class _HfTokenTile extends ConsumerStatefulWidget {
  const _HfTokenTile();

  @override
  ConsumerState<_HfTokenTile> createState() => _HfTokenTileState();
}

class _HfTokenTileState extends ConsumerState<_HfTokenTile> {
  bool? _hasToken;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final has = await ref.read(modelDownloadServiceProvider).hasHfToken();
    if (mounted) setState(() => _hasToken = has);
  }

  Future<void> _clear() async {
    await ref.read(modelDownloadServiceProvider).clearHfToken();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasToken != true) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OHCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HuggingFace token', style: textTheme.labelLarge),
                  Text('Stored for gated model downloads.',
                      style: textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(onPressed: _clear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}

/// Export card with its own busy state and user feedback. Extracted from
/// [SettingsScreen] so the share pipeline can show progress and surface
/// failures (a bare share call gave the user nothing on error).
class _ExportCard extends ConsumerStatefulWidget {
  const _ExportCard();

  @override
  ConsumerState<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<_ExportCard> {
  bool _busy = false;

  Future<void> _export({required bool asMarkdown}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final svc = ref.read(exportServiceProvider);
      final bundle = await svc.gather();
      final content = asMarkdown
          ? ExportFormatters.toMarkdown(bundle)
          : ExportFormatters.toJson(bundle);
      final ext = asMarkdown ? 'md' : 'json';
      final stamp = bundle.generatedAt
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'reckon-export-$stamp.$ext'));
      await file.writeAsBytes(utf8.encode(content), flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Reckon export — $stamp',
        text: 'My Reckon data (generated $stamp)',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export everything Reckon knows about you: cases, polls, '
            'outside views, and resolutions. Stays on your device '
            'unless you share it.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OHButton(
                    label: 'Markdown',
                    style: OHButtonStyle.secondary,
                    onPressed: () => _export(asMarkdown: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OHButton(
                    label: 'JSON',
                    onPressed: () => _export(asMarkdown: false),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final current = ref.watch(themePreferenceProvider).valueOrNull ??
        ThemePreference.light;

    return OHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reckon ships three themes. Light is the daytime default; '
            'Evening is warm-dark for reflective check-ins; Late night is '
            'neutral high-contrast for long reading or low ambient light.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final pref in ThemePreference.values)
            _ThemeRow(
              pref: pref,
              isSelected: pref == current,
              onTap: () async {
                await setThemePreference(pref);
                ref.invalidate(themePreferenceProvider);
              },
              accent: colors.primary,
            ),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.pref,
    required this.isSelected,
    required this.onTap,
    required this.accent,
  });

  final ThemePreference pref;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? accent : null,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pref.label, style: textTheme.labelLarge),
                  Text(pref.hint, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelCard extends ConsumerStatefulWidget {
  const _ModelCard({required this.spec, required this.isSelected});
  final ReckonModelSpec spec;
  final bool isSelected;

  @override
  ConsumerState<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends ConsumerState<_ModelCard> {
  bool? _isDownloaded;
  bool _downloading = false;
  double _progress = 0;
  String? _downloadError;
  StreamSubscription<(int, int)>? _sub;

  @override
  void initState() {
    super.initState();
    _refreshDownloadState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refreshDownloadState() async {
    final svc = ref.read(modelDownloadServiceProvider);
    final downloaded = await svc.isDownloaded(widget.spec);
    if (mounted) setState(() => _isDownloaded = downloaded);
  }

  Future<void> _download() async {
    // Cancel any stale subscription before starting a new one so retrying
    // after an error doesn't leak listeners and double-toggle state.
    await _sub?.cancel();
    _sub = null;

    final svc = ref.read(modelDownloadServiceProvider);
    if (!mounted) return;
    if (!await ensureHfToken(context, svc, widget.spec)) return;
    if (!mounted) return;
    setState(() {
      _downloading = true;
      _downloadError = null;
      _progress = 0;
    });
    _sub = svc.download(widget.spec).listen(
      (event) {
        final (received, total) = event;
        if (total > 0 && mounted) {
          setState(() => _progress = received / total);
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _downloading = false;
            _isDownloaded = true;
          });
        }
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _downloading = false;
            _downloadError = e.toString();
          });
        }
      },
    );
  }

  Future<void> _delete() async {
    final sizeMb = (widget.spec.approximateSizeBytes / 1e6).round();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete model?'),
        content: Text(
          '${widget.spec.displayName} (~$sizeMb MB) will be removed from this '
          'device. You can download it again later.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final svc = ref.read(modelDownloadServiceProvider);
    await svc.delete(widget.spec);
    if (!mounted) return;
    setState(() => _isDownloaded = false);
    // If the deleted model was active, fall back to the default so the
    // LLM service doesn't try to load a missing file on next invocation.
    if (widget.isSelected && widget.spec.id != ReckonModelSpec.gemma3_1b.id) {
      await persistSelectedModelId(ReckonModelSpec.gemma3_1b.id);
      ref.invalidate(selectedModelIdProvider);
      ref.invalidate(llmServiceProvider);
    }
  }

  Future<void> _select() async {
    if (widget.isSelected) return;
    await persistSelectedModelId(widget.spec.id);
    ref.invalidate(selectedModelIdProvider);
    // The native InferenceModel has to be rebuilt because flutter_gemma
    // only holds one active model at a time.
    ref.invalidate(llmServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final sizeMb = (widget.spec.approximateSizeBytes / 1e6).round();

    return OHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: widget.isSelected ? colors.primary : null,
                ),
                onPressed: _isDownloaded == true ? _select : null,
                tooltip: _isDownloaded == true
                    ? (widget.isSelected ? 'Active' : 'Select')
                    : 'Download to select',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.spec.displayName, style: textTheme.labelLarge),
                    Text('~$sizeMb MB', style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (widget.isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: textTheme.labelSmall?.copyWith(color: colors.primary),
                  ),
                ),
            ],
          ),
          if (widget.spec.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.spec.description, style: textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          if (_isDownloaded == null)
            const Center(child: CircularProgressIndicator())
          else if (_isDownloaded == true)
            Row(
              children: [
                Icon(Icons.check_circle, color: colors.primary),
                const SizedBox(width: 8),
                Text('Downloaded', style: textTheme.bodyMedium),
                const Spacer(),
                TextButton(onPressed: _delete, child: const Text('Delete')),
              ],
            )
          else if (!_downloading)
            OHButton(
              label: 'Download',
              expanded: true,
              onPressed: _download,
            ),
          if (_downloading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 4),
            Text('${(_progress * 100).toStringAsFixed(0)}%',
                style: textTheme.bodySmall),
          ],
          if (_downloadError != null) ...[
            const SizedBox(height: 8),
            Text(
              _downloadError!,
              style: textTheme.bodySmall?.copyWith(color: colors.error),
            ),
            const SizedBox(height: 8),
            OHButton(
              label: 'Retry',
              style: OHButtonStyle.secondary,
              onPressed: _download,
            ),
          ],
        ],
      ),
    );
  }
}

