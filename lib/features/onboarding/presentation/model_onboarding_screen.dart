import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/llm/hf_token.dart';
import '../../../core/llm/llm_providers.dart';
import '../../../core/llm/model_spec.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../core/llm/model_error.dart';

/// First-class onboarding step that picks and downloads an on-device model.
/// Follows the Ghost tier selection and precedes the first-case prompt —
/// the app literally can't reason without a model, so the choice belongs
/// in the main flow, not buried in Settings.
///
/// Auto-advances to the next step if any model is already downloaded
/// (returning user, re-onboarding after a seed wipe, etc).
class ModelOnboardingScreen extends ConsumerStatefulWidget {
  const ModelOnboardingScreen({super.key});

  @override
  ConsumerState<ModelOnboardingScreen> createState() =>
      _ModelOnboardingScreenState();
}

class _ModelOnboardingScreenState
    extends ConsumerState<ModelOnboardingScreen> {
  ReckonModelSpec _selected = ReckonModelSpec.qwen25_1_5b;
  bool _downloading = false;
  double _progress = 0;
  String? _error;
  StreamSubscription<(int, int)>? _sub;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoAdvanceIfReady());
  }

  @override
  void dispose() {
    _sub?.cancel();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  Future<void> _autoAdvanceIfReady() async {
    // No runtime (the web build): nothing to check and nothing worth
    // fetching. The build method shows one honest card instead of the picker.
    if (!ref.read(onDeviceModelSupportedProvider)) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    final svc = ref.read(modelDownloadServiceProvider);
    for (final spec in ReckonModelSpec.availableModels) {
      if (await svc.isDownloaded(spec)) {
        await persistSelectedModelId(spec.id);
        ref.invalidate(selectedModelIdProvider);
        if (mounted) context.go('/onboarding/first-case');
        return;
      }
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _download() async {
    await _sub?.cancel();
    _sub = null;
    final svc = ref.read(modelDownloadServiceProvider);
    if (!mounted) return;
    if (!await ensureHfToken(context, svc, _selected)) return;
    if (!mounted) return;
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    // Hold the CPU awake while the (large) model downloads so the screen
    // sleeping can't get Android to suspend the transfer mid-flight.
    unawaited(WakelockPlus.enable());
    _sub = svc.download(_selected).listen(
      (event) {
        final (received, total) = event;
        if (total > 0 && mounted) {
          setState(() => _progress = received / total);
        }
      },
      onDone: () async {
        unawaited(WakelockPlus.disable());
        await persistSelectedModelId(_selected.id);
        if (!mounted) return;
        ref.invalidate(selectedModelIdProvider);
        context.go('/onboarding/first-case');
      },
      onError: (Object e) {
        unawaited(WakelockPlus.disable());
        debugPrint('Reckon: model download failed: $e');
        if (mounted) {
          setState(() {
            _downloading = false;
            _error = modelDownloadErrorMessage(e);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_checking) {
      return const Scaffold(
        body: OhPage(
          padding: EdgeInsets.zero,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!ref.watch(onDeviceModelSupportedProvider)) {
      return _NoRuntimeStep(onContinue: () => context.go('/'));
    }

    return Scaffold(
      body: OhPage(
        padding: EdgeInsets.zero,
        child: SafeArea(
          // The choices scroll; progress, error and the actions are pinned
          // below so Download stays on screen at large text on small phones.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text('Pick a brain.', style: textTheme.displayMedium),
                      const SizedBox(height: 12),
                      Text(
                        'Reckon thinks on your device, not in a data center. Pick '
                        'the small language model it uses. You can change this '
                        'later in Settings.',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      for (final spec in ReckonModelSpec.availableModels)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ModelChoice(
                            spec: spec,
                            isSelected: spec.id == _selected.id,
                            disabled: _downloading,
                            onTap: () => setState(() => _selected = spec),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_downloading) ...[
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 6),
                      Text(
                        'Downloading ${_selected.displayName}… '
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // The selected card names the model; the button carries
                    // only the verb and the cost so it fits in one line at
                    // large text instead of ellipsizing mid-name.
                    OHButton(
                      label: _downloading
                          ? 'Downloading…'
                          : 'Download '
                              '(~${(_selected.approximateSizeBytes / 1e6).round()} MB)',
                      expanded: true,
                      onPressed: _downloading ? null : _download,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _downloading
                            ? null
                            : () => context.go('/onboarding/first-case'),
                        child: const Text('Skip for now'),
                      ),
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

/// Shown instead of the model picker on a build that cannot run a local
/// model (the web PWA). Offering a ~1.6 GB download there would cost the user
/// time and data for a file nothing can load.
class _NoRuntimeStep extends StatelessWidget {
  const _NoRuntimeStep({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: OhPage(
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                  child: OHCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No model to download here',
                            style: textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          "Reckon’s interviewer runs a language model on your "
                          "device, and this browser version can’t run one. "
                          'You can still write decisions down yourself here. '
                          'The Android app adds the interviewer, the outside '
                          'view and the forecasters.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: OHButton(
                  label: 'Continue',
                  expanded: true,
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelChoice extends StatelessWidget {
  const _ModelChoice({
    required this.spec,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final ReckonModelSpec spec;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final sizeMb = (spec.approximateSizeBytes / 1e6).round();

    return OHCard(
      onTap: disabled ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected ? colors.primary : colors.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap, not Row: at large text the name, size and badge
                // flow onto a second line instead of overflowing.
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(spec.displayName, style: textTheme.titleLarge),
                    Text('~$sizeMb MB',
                        style: textTheme.bodySmall),
                    if (spec.requiresToken) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'HF token',
                          style: textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ],
                ),
                if (spec.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(spec.description, style: textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
