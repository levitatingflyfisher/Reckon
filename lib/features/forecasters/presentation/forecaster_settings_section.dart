import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/llm/anthropic_key_store.dart';
import '../../../core/llm/stove_secret_store.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../data/forecaster_providers.dart';
import '../domain/entities/forecaster.dart';

/// The Forecasters block of the Settings screen: the BYOK key card, the
/// roster with enable switches, and the add/edit minimal forms. Lives in the
/// forecasters feature (imported by settings_screen.dart) so the roster UI
/// stays next to its providers.
class ForecastersSection extends ConsumerWidget {
  const ForecastersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final roster = ref.watch(forecastersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forecasters', style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Rivals for your own judgment. Each one gives a sealed forecast '
          'when you run the duel on an open decision — and earns a track '
          'record when you record how it turned out.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        const _AnthropicKeyCard(),
        const _StovePhraseCard(),
        roster.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load forecasters: $e',
              style: textTheme.bodyMedium),
          data: (forecasters) => Column(
            children: [
              for (final f in forecasters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ForecasterTile(forecaster: f),
                ),
            ],
          ),
        ),
        OHButton(
          label: 'Add forecaster',
          style: OHButtonStyle.secondary,
          expanded: true,
          onPressed: () => _showEditor(context, ref),
        ),
      ],
    );
  }
}

/// Roster mutations always ripple to the duel button's runnability check.
void _invalidateRoster(WidgetRef ref) {
  ref.invalidate(forecastersProvider);
  ref.invalidate(enabledForecastersProvider);
  ref.invalidate(runnableForecastersProvider);
}

Future<void> _showEditor(BuildContext context, WidgetRef ref,
    {Forecaster? existing}) async {
  final result = await showDialog<_EditorResult>(
    context: context,
    builder: (_) => _ForecasterEditorDialog(existing: existing),
  );
  if (result == null) return;
  final repo = ref.read(forecasterRepositoryProvider);
  switch (result) {
    case _SaveForecaster(:final forecaster):
      await repo.upsert(forecaster);
    case _DeleteForecaster(:final id):
      await repo.delete(id);
  }
  _invalidateRoster(ref);
}

String _kindLabel(ForecasterKind kind) => switch (kind) {
      ForecasterKind.persona => 'Persona · resident model',
      ForecasterKind.localModel => 'Resident model',
      ForecasterKind.anthropicByok => 'Claude · your key',
      ForecasterKind.openaiCompat => 'HTTP endpoint',
      ForecasterKind.stove => 'Household stove',
      ForecasterKind.bountyBot => 'Outside bot · imported',
    };

class _ForecasterTile extends ConsumerWidget {
  const _ForecasterTile({required this.forecaster});

  final Forecaster forecaster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return OHCard(
      onTap: () => _showEditor(context, ref, existing: forecaster),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(forecaster.displayName,
                    style: textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis),
                Text(_kindLabel(forecaster.kind),
                    style: textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch(
            value: forecaster.enabled,
            onChanged: (enabled) async {
              await ref
                  .read(forecasterRepositoryProvider)
                  .setEnabled(forecaster.id, enabled);
              _invalidateRoster(ref);
            },
          ),
        ],
      ),
    );
  }
}

sealed class _EditorResult {}

class _SaveForecaster extends _EditorResult {
  _SaveForecaster(this.forecaster);
  final Forecaster forecaster;
}

class _DeleteForecaster extends _EditorResult {
  _DeleteForecaster(this.id);
  final String id;
}

/// Minimal add/edit form. Pure UI: pops a [_EditorResult]; the caller
/// persists and invalidates. Owns its controllers so they outlive the
/// dialog's dismiss animation (same reasoning as the HF-token dialog).
class _ForecasterEditorDialog extends StatefulWidget {
  const _ForecasterEditorDialog({this.existing});

  final Forecaster? existing;

  @override
  State<_ForecasterEditorDialog> createState() =>
      _ForecasterEditorDialogState();
}

class _ForecasterEditorDialogState extends State<_ForecasterEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _persona;
  late final TextEditingController _model;
  late final TextEditingController _baseUrl;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late ForecasterKind _kind;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _kind = f?.kind ?? ForecasterKind.persona;
    _name = TextEditingController(text: f?.displayName ?? '');
    _persona =
        TextEditingController(text: f?.config['persona'] as String? ?? '');
    _model = TextEditingController(text: f?.config['model'] as String? ?? '');
    _baseUrl =
        TextEditingController(text: f?.config['base_url'] as String? ?? '');
    _host = TextEditingController(text: f?.config['host'] as String? ?? '');
    _port = TextEditingController(
        text: (f?.config['port'] as num?)?.toInt().toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _persona.dispose();
    _model.dispose();
    _baseUrl.dispose();
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final config = switch (_kind) {
      ForecasterKind.persona => {
          if (_persona.text.trim().isNotEmpty) 'persona': _persona.text.trim(),
        },
      ForecasterKind.anthropicByok => {
          if (_model.text.trim().isNotEmpty) 'model': _model.text.trim(),
        },
      ForecasterKind.openaiCompat => {
          'base_url': _baseUrl.text.trim(),
          if (_model.text.trim().isNotEmpty) 'model': _model.text.trim(),
        },
      ForecasterKind.stove => {
          'host': _host.text.trim(),
          // The port is optional — blank means domovoi's stove default.
          if (int.tryParse(_port.text.trim()) != null)
            'port': int.parse(_port.text.trim()),
        },
      // localModel needs no config; bountyBot keeps whatever import wrote.
      _ => widget.existing?.config ?? const <String, dynamic>{},
    };
    if (_kind == ForecasterKind.openaiCompat &&
        (config['base_url'] as String).isEmpty) {
      return; // an endpoint forecaster without an endpoint is nothing
    }
    if (_kind == ForecasterKind.stove && (config['host'] as String).isEmpty) {
      return; // a stove forecaster without a host is nothing
    }
    final forecaster = widget.existing != null
        ? widget.existing!.copyWith(displayName: name, config: config)
        : Forecaster(
            id: 'custom-${const Uuid().v4()}',
            displayName: name,
            kind: _kind,
            config: config,
            createdAt: DateTime.now(),
          );
    Navigator.of(context).pop(_SaveForecaster(forecaster));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isNew = widget.existing == null;

    return AlertDialog(
      title: Text(isNew ? 'Add forecaster' : 'Edit forecaster'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNew) ...[
              DropdownButtonFormField<ForecasterKind>(
                initialValue: _kind,
                items: const [
                  DropdownMenuItem(
                    value: ForecasterKind.persona,
                    child: Text('Persona (resident model)'),
                  ),
                  DropdownMenuItem(
                    value: ForecasterKind.anthropicByok,
                    child: Text('Claude (your key)'),
                  ),
                  DropdownMenuItem(
                    value: ForecasterKind.openaiCompat,
                    child: Text('HTTP endpoint'),
                  ),
                  DropdownMenuItem(
                    value: ForecasterKind.stove,
                    child: Text('Household stove'),
                  ),
                ],
                onChanged: (kind) =>
                    setState(() => _kind = kind ?? ForecasterKind.persona),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(_kindLabel(_kind), style: textTheme.bodySmall),
              const SizedBox(height: 12),
            ],
            OHTextField(controller: _name, label: 'Name'),
            const SizedBox(height: 12),
            if (_kind == ForecasterKind.persona)
              OHTextField(
                controller: _persona,
                label: 'Stance',
                hint: 'One sentence: how this forecaster thinks',
                maxLines: 3,
              ),
            if (_kind == ForecasterKind.anthropicByok)
              OHTextField(
                controller: _model,
                label: 'Model',
                hint: 'claude-sonnet-4-6',
              ),
            if (_kind == ForecasterKind.openaiCompat) ...[
              OHTextField(
                controller: _baseUrl,
                label: 'Base URL',
                hint: 'http://192.168.1.20:8080',
              ),
              const SizedBox(height: 12),
              OHTextField(
                controller: _model,
                label: 'Model',
                hint: 'as the server names it',
              ),
            ],
            if (_kind == ForecasterKind.stove) ...[
              OHTextField(
                controller: _host,
                label: 'Host',
                hint: '192.168.1.30',
              ),
              const SizedBox(height: 12),
              OHTextField(
                controller: _port,
                // Display hint only — the real default is domovoi's
                // kStovePort, applied where the client is built.
                label: 'Port',
                hint: '4663 (the stove default)',
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!isNew)
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(_DeleteForecaster(widget.existing!.id)),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// The user's Anthropic key: add when absent, clear when present. The key
/// never leaves secure storage except toward api.anthropic.com (ADR-0002).
class _AnthropicKeyCard extends ConsumerWidget {
  const _AnthropicKeyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasKey = ref.watch(hasAnthropicKeyProvider).valueOrNull ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OHCard(
        child: hasKey
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Anthropic API key', style: textTheme.labelLarge),
                        Text(
                          'Stored on this device only — used for Claude '
                          'forecasters.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(anthropicKeyStoreProvider).clearKey();
                      ref.invalidate(hasAnthropicKeyProvider);
                      ref.invalidate(runnableForecastersProvider);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Claude forecasters run on your own Anthropic API key. '
                    'It is stored on this device only and sent nowhere but '
                    'Anthropic.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  OHButton(
                    label: 'Add key',
                    style: OHButtonStyle.secondary,
                    expanded: true,
                    onPressed: () => _promptForKey(context, ref),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _promptForKey(BuildContext context, WidgetRef ref) async {
    final entered = await showDialog<String>(
      context: context,
      builder: (_) => const _KeyDialog(),
    );
    if (entered == null || entered.isEmpty) return;
    await ref.read(anthropicKeyStoreProvider).setKey(entered);
    ref.invalidate(hasAnthropicKeyProvider);
    ref.invalidate(runnableForecastersProvider);
  }
}

/// The household phrase pairing this device with the family's stove. The
/// phrase never leaves secure storage; prompts to a stove forecaster go
/// encrypted to the household's own machine and nowhere else.
class _StovePhraseCard extends ConsumerWidget {
  const _StovePhraseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasPhrase = ref.watch(hasStovePhraseProvider).valueOrNull ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OHCard(
        child: hasPhrase
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Household phrase', style: textTheme.labelLarge),
                        Text(
                          'Stored on this device only — used for stove '
                          'forecasters.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(stoveSecretStoreProvider).clearPhrase();
                      ref.invalidate(hasStovePhraseProvider);
                      ref.invalidate(runnableForecastersProvider);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stove forecasters run on your household\'s own machine. '
                    'Prompts go encrypted to it and nowhere else — both ends '
                    'just share the same household phrase.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  OHButton(
                    label: 'Add phrase',
                    style: OHButtonStyle.secondary,
                    expanded: true,
                    onPressed: () => _promptForPhrase(context, ref),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _promptForPhrase(BuildContext context, WidgetRef ref) async {
    final entered = await showDialog<String>(
      context: context,
      builder: (_) => const _PhraseDialog(),
    );
    if (entered == null || entered.isEmpty) return;
    await ref.read(stoveSecretStoreProvider).setPhrase(entered);
    ref.invalidate(hasStovePhraseProvider);
    ref.invalidate(runnableForecastersProvider);
  }
}

/// Owns the controller so it is disposed with the dialog, not synchronously
/// after `showDialog` returns (house pattern from the HF-token dialog).
class _PhraseDialog extends StatefulWidget {
  const _PhraseDialog();

  @override
  State<_PhraseDialog> createState() => _PhraseDialogState();
}

class _PhraseDialogState extends State<_PhraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Household phrase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type the same phrase the stove was started with. Stored '
            'securely on this device only.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OHTextField(controller: _controller, hint: 'the household phrase'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Owns the controller so it is disposed with the dialog, not synchronously
/// after `showDialog` returns (house pattern from the HF-token dialog).
class _KeyDialog extends StatefulWidget {
  const _KeyDialog();

  @override
  State<_KeyDialog> createState() => _KeyDialogState();
}

class _KeyDialogState extends State<_KeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anthropic API key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste a key from console.anthropic.com. Stored securely on '
            'this device only.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OHTextField(controller: _controller, hint: 'sk-ant-...'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
