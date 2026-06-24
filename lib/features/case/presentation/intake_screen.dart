import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/llm/llm_providers.dart';
import '../../../core/llm/llm_service.dart';
import '../../../core/llm/model_spec.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../domain/entities/case.dart';
import '../domain/entities/criterion.dart';
import 'case_summary_screen.dart';

class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  final _input = TextEditingController();
  final _transcript = <IntakeTurn>[];
  String _streamingBuf = '';
  bool _isGenerating = false;
  bool? _modelReady;
  StreamSubscription<String>? _sub;
  int _jsonRetries = 0;
  bool _gaveUp = false;
  static const _maxJsonRetries = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _gateOnModel());
  }

  /// Opening question shown immediately on screen entry, without hitting
  /// the LLM. Using a static greeting keeps the Send button responsive —
  /// invoking `generateChatResponseAsync` before the user has typed
  /// anything leaves the stream open-ended on some Gemma builds, which
  /// would pin `_isGenerating` to true and disable Send forever.
  static const _opener = IntakeTurn(
    role: IntakeRole.assistant,
    content: "What's the decision you're trying to make?",
  );

  /// Block the intake conversation until we know a model is installed.
  /// This is Reckon's first-run failure mode: the user finishes
  /// onboarding, lands here, and there's nothing to talk to. Instead of
  /// surfacing a raw StateError in the chat bubble, show a dedicated
  /// "download a model first" screen with a direct Settings link.
  Future<void> _gateOnModel() async {
    // Resolve the *actual* selected model before checking the filesystem.
    // activeModelSpecProvider is synchronous and derives from the async
    // selectedModelIdProvider; reading it here — before that future
    // resolves — always falls back to the default Gemma spec, which wrongly
    // gates out anyone who picked Qwen or Phi-4. Await the selection first.
    final selectedId = await ref.read(selectedModelIdProvider.future);
    final spec = ReckonModelSpec.byId(selectedId);
    final svc = ref.read(modelDownloadServiceProvider);
    final ready = await svc.isDownloaded(spec);
    if (!mounted) return;
    setState(() {
      _modelReady = ready;
      if (ready && _transcript.isEmpty) {
        _transcript.add(_opener);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _sendUserTurn(String userText) async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _streamingBuf = '';
      if (userText.isNotEmpty) {
        _transcript.add(IntakeTurn(role: IntakeRole.user, content: userText));
      }
      _input.clear();
    });

    try {
      final svc = await ref.read(llmServiceProvider.future);
      final ctx = IntakeContext(
        transcript: List.of(_transcript),
        userInput: userText,
      );

      _sub = svc.conductIntake(ctx).listen(
        (delta) {
          if (!mounted) return;
          setState(() => _streamingBuf += delta);
        },
        onDone: () {
          // The stream can complete from an in-flight microtask after the user
          // backs out mid-generation; guard against setState/navigation on a
          // disposed State.
          if (!mounted) return;
          final full = _streamingBuf;
          setState(() {
            _transcript
                .add(IntakeTurn(role: IntakeRole.assistant, content: full));
            _isGenerating = false;
          });
          _checkForCompletion(full);
        },
        onError: (e) {
          debugPrint('Intake stream error: $e');
          if (!mounted) return;
          setState(() {
            _transcript.add(const IntakeTurn(
              role: IntakeRole.assistant,
              content: 'The intake assistant had an error. Try again?',
            ));
            _isGenerating = false;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _transcript.add(IntakeTurn(
            role: IntakeRole.assistant,
            content: 'The on-device model is not available yet. '
                'Download it from Settings before starting a case.\n\n'
                '($e)',
          ));
          _isGenerating = false;
        });
      }
    }
  }

  void _checkForCompletion(String assistantText) {
    if (_gaveUp) return;
    final marker = assistantText.indexOf('INTAKE_COMPLETE');
    if (marker < 0) return;
    final jsonText =
        assistantText.substring(marker + 'INTAKE_COMPLETE'.length).trim();
    try {
      final draft = _parseDraft(jsonText);
      _jsonRetries = 0;
      if (mounted) context.go('/case-summary', extra: draft);
    } catch (_) {
      _jsonRetries++;
      if (_jsonRetries >= _maxJsonRetries) {
        _gaveUp = true;
        if (mounted) {
          setState(() {
            _transcript.add(const IntakeTurn(
              role: IntakeRole.assistant,
              content: "I wasn't able to structure your case automatically. "
                  "You can try describing your decision again, or tap the "
                  "back button and create a new case.",
            ));
          });
        }
      } else {
        _sendUserTurn('Can you emit the JSON one more time? Just the JSON.');
      }
    }
  }

  CaseDraft _parseDraft(String jsonText) {
    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
    return CaseDraft(
      question: parsed['question'] as String,
      optionA: parsed['optionA'] as String,
      optionB: parsed['optionB'] as String,
      stakes: _parseStakes(parsed['stakes'] as String?),
      regretHorizon: _parseHorizon(parsed['regretHorizon'] as String?),
      deadline: parsed['deadline'] == null
          ? null
          : DateTime.tryParse(parsed['deadline'] as String),
      statedCriteria: (parsed['statedCriteria'] as List? ?? [])
          .map((raw) => Criterion.fromJson(raw as Map<String, dynamic>))
          .toList(),
      category: parsed['category'] as String?,
    );
  }

  Stakes _parseStakes(String? s) =>
      Stakes.values.firstWhere((e) => e.name == s, orElse: () => Stakes.medium);
  RegretHorizon _parseHorizon(String? s) => RegretHorizon.values
      .firstWhere((e) => e.name == s, orElse: () => RegretHorizon.months);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_modelReady == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New case')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_modelReady == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('New case')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reckon needs an on-device model before it can open a case.',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Head to Settings, pick a model, and tap Download. It "
                  "stays on your phone — nothing leaves the device.",
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OHButton(
                  label: 'Open Settings',
                  expanded: true,
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('New case')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (final turn in _transcript)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: turn.role == IntakeRole.user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: turn.role == IntakeRole.user
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child:
                                Text(turn.content, style: textTheme.bodyLarge),
                          ),
                        ),
                      ),
                    ),
                  if (_isGenerating && _streamingBuf.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child:
                              Text(_streamingBuf, style: textTheme.bodyLarge),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OHTextField(
                    controller: _input,
                    hint: 'Type your answer...',
                    onSubmitted: _sendUserTurn,
                  ),
                ),
                const SizedBox(width: 12),
                OHButton(
                  label: 'Send',
                  onPressed: _isGenerating
                      ? null
                      : () => _sendUserTurn(_input.text.trim()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
