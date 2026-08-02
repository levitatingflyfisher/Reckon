import 'dart:convert';

import 'package:domovoi/domovoi.dart'
    show Brain, DomovoiKeys, StoveClient, kStovePort;

import '../../features/case/domain/entities/case.dart';
import '../../features/outside_view/domain/entities/reference_class_entry.dart';
import '../../features/outside_view/domain/entities/user_profile.dart';
import '../../features/reveal/domain/entities/case_time_series.dart';
import '../../features/reveal/domain/entities/reveal_observation.dart';
import 'anthropic_client.dart' show intakeMessages;
import 'llm_prompts.dart';
import 'llm_service.dart';

/// Builds the [LlmService] for a stove forecaster, or null when it cannot be
/// configured. [port] falls back to domovoi's [kStovePort]; [phrase] is the
/// household phrase (validated per ask — a bad phrase surfaces as the same
/// calm sentinel any stove failure does).
LlmService? buildStoveLlmService({
  required String host,
  int? port,
  required String phrase,
}) {
  if (host.isEmpty || phrase.isEmpty) return null;
  return StoveLlmService(StoveClient(
    host: host,
    port: port ?? kStovePort,
    secret: () => DomovoiKeys.seedFromPhrase(phrase),
  ));
}

/// [LlmService] over the household stove — domovoi's [Brain] seam, normally a
/// [StoveClient] speaking the encrypted stove protocol to the family's own
/// machine. Mirrors [OpenAiCompatLlmService]: same shared [LlmPrompts], same
/// sentinel-not-throw error policy.
///
/// A [Brain] takes ONE prompt, so chat context is flattened into a single
/// text: system prompt first, then the transcript as role-labeled lines,
/// capped at the local-model path's replay budget (the stove's model is the
/// same class of small model, with the same tiny context). Temperature has no
/// slot on the stove wire — the stove's upstream decides sampling.
class StoveLlmService implements LlmService {
  StoveLlmService(this._brain, {String modelVersion = 'household-stove'})
      : _modelVersion = modelVersion;

  final Brain _brain;
  final String _modelVersion;

  /// The local-model path's replay cap (see PrivateModeImpl.conductIntake):
  /// a small model's context is tiny, and the last dozen turns are plenty
  /// for a four-question intake.
  static const _maxReplayTurns = 12;

  @override
  String get modelVersion => _modelVersion;

  @override
  Stream<String> conductIntake(IntakeContext ctx) async* {
    try {
      final text = await _brain.complete(_flattenIntake(ctx));
      if (text.isNotEmpty) yield text;
    } catch (_) {
      // Recoverable: an empty stream lets the UI show its own fallback.
    }
  }

  @override
  Future<OutsideViewResult> synthesizeOutsideView(
    Case case_,
    ReferenceClassEntry ref,
    UserProfile profile,
  ) async {
    try {
      final text = await _brain.complete(_flatten(
        LlmPrompts.outsideViewSynthesizer,
        _outsideViewPrompt(case_, ref, profile),
      ));
      return OutsideViewResult(
        baseRateSummary: text,
        referenceClassUsed: '${ref.category} / ${ref.subcategory}',
        uncertaintyLevel: ref.uncertaintyLevel,
        stratificationFactors: {
          if (profile.sesBracket != null) 'ses': profile.sesBracket,
          if (profile.religiosity != null) 'religiosity': profile.religiosity,
          if (profile.relationshipStatus != null)
            'relationship': profile.relationshipStatus,
        },
        modelVersion: _modelVersion,
      );
    } catch (_) {
      return OutsideViewResult(
        baseRateSummary:
            'Unable to generate outside view — the request failed.',
        referenceClassUsed: '${ref.category} / ${ref.subcategory}',
        uncertaintyLevel: 'unknown',
        stratificationFactors: const {},
        modelVersion: _modelVersion,
      );
    }
  }

  @override
  Future<MismatchResult> detectRepollSentiment(
      int lean, String rationale) async {
    try {
      final text = await _brain.complete(_flatten(
        LlmPrompts.repollSentimentDetector,
        'Lean score: $lean\nRationale: $rationale',
      ));
      final json = _firstJsonObject(text);
      if (json != null) {
        return MismatchResult(
          mismatch: json['mismatch'] as bool? ?? false,
          observation: json['observation'] as String? ?? '',
        );
      }
      return const MismatchResult(mismatch: false, observation: '');
    } catch (_) {
      return const MismatchResult(mismatch: false, observation: '');
    }
  }

  @override
  Future<RevealObservation> generateRevealObservation(
    CaseTimeSeries timeSeries,
  ) async {
    try {
      final text = await _brain.complete(_flatten(
        LlmPrompts.revealObservation,
        _revealPrompt(timeSeries),
      ));
      if (text.trim().isEmpty) {
        return const RevealObservation(
          text: 'Your position held steady — '
              'your initial lean appears stable.',
        );
      }
      return RevealObservation(text: text.trim());
    } catch (_) {
      return const RevealObservation(
        text: 'Unable to generate observation — the request failed.',
      );
    }
  }

  @override
  Future<CommunitySeed> generateCommunitySeed(
    Case case_, {
    String? persona,
    double? temperature,
  }) async {
    try {
      final text = await _brain.complete(_flatten(
        LlmPrompts.forecasterSeed(persona),
        LlmPrompts.decisionBrief(case_),
      ));
      final json = _firstJsonObject(text);
      if (json != null && json['lean'] is num) {
        return CommunitySeed(
          lean: (json['lean'] as num).round().clamp(0, 100),
          rationale: json['rationale'] as String? ?? '',
        );
      }
      return const CommunitySeed(lean: 50, rationale: '');
    } catch (_) {
      return const CommunitySeed(lean: 50, rationale: '');
    }
  }

  @override
  Future<RedactedQuestion> redactQuestion({
    required String title,
    required String background,
  }) async {
    try {
      final text = await _brain.complete(_flatten(
        LlmPrompts.redactor,
        'TITLE: $title\nBACKGROUND: $background',
      ));
      final json = _firstJsonObject(text);
      final newTitle = (json?['title'] as String?)?.trim() ?? '';
      final newBackground = (json?['background'] as String?)?.trim() ?? '';
      if (newTitle.isEmpty || newBackground.isEmpty) {
        return RedactedQuestion.sentinel;
      }
      return RedactedQuestion(title: newTitle, background: newBackground);
    } catch (_) {
      return RedactedQuestion.sentinel;
    }
  }

  // --- flattening (one prompt in, text out) ---------------------------------

  /// System prompt first, one blank line, then the user message — the
  /// single-turn shape every structured call uses.
  String _flatten(String system, String userMessage) =>
      '$system\n\n$userMessage';

  /// Maps the intake transcript through the shared [intakeMessages] mapper
  /// (empty turns dropped), keeps only the last [_maxReplayTurns], and lays
  /// the turns out as role-labeled lines with a trailing `Assistant:` cue.
  String _flattenIntake(IntakeContext ctx) {
    final messages = intakeMessages(ctx);
    final recent = messages.length > _maxReplayTurns
        ? messages.sublist(messages.length - _maxReplayTurns)
        : messages;
    final sb = StringBuffer(LlmPrompts.intakeInterviewer)
      ..writeln()
      ..writeln();
    for (final m in recent) {
      sb.writeln(
          '${m['role'] == 'user' ? 'User' : 'Assistant'}: ${m['content']}');
    }
    sb.write('Assistant:');
    return sb.toString();
  }

  // --- prompt builders (mirror the other backends) --------------------------

  String _outsideViewPrompt(
    Case case_,
    ReferenceClassEntry ref,
    UserProfile profile,
  ) {
    final sb = StringBuffer()
      ..writeln('CASE SUMMARY')
      ..writeln('Question: ${case_.question}')
      ..writeln('Option A: ${case_.optionA}')
      ..writeln('Option B: ${case_.optionB}')
      ..writeln('Stakes: ${case_.stakes.name}')
      ..writeln('Category: ${case_.category ?? "uncategorised"}')
      ..writeln()
      ..writeln('REFERENCE CLASS')
      ..writeln('${ref.category} / ${ref.subcategory}')
      ..writeln('Base rate: ${ref.baseRateDescription}')
      ..writeln('Uncertainty: ${ref.uncertaintyLevel}')
      ..writeln(
          'Stratification variables: ${ref.stratificationVariables.join(", ")}')
      ..writeln()
      ..writeln('USER PROFILE');
    if (profile.sesBracket != null) {
      sb.writeln('SES bracket: ${profile.sesBracket}');
    }
    if (profile.religiosity != null) {
      sb.writeln('Religiosity: ${profile.religiosity}');
    }
    if (profile.relationshipStatus != null) {
      sb.writeln('Relationship status: ${profile.relationshipStatus}');
    }
    if (profile.sesBracket == null &&
        profile.religiosity == null &&
        profile.relationshipStatus == null) {
      sb.writeln('(No stratification data provided.)');
    }
    return sb.toString();
  }

  String _revealPrompt(CaseTimeSeries timeSeries) {
    final sb = StringBuffer()
      ..writeln('DECISION TIME SERIES')
      ..writeln('Category: ${timeSeries.category}')
      ..writeln('Deadline: ${timeSeries.deadline?.toIso8601String() ?? "none"}')
      ..writeln('Final choice: ${timeSeries.finalChoice}')
      ..writeln(
          'Stated criteria: ${timeSeries.statedCriteria.map((c) => c.toString()).join(", ")}')
      ..writeln()
      ..writeln('POLLS (chronological):');
    for (final poll in timeSeries.polls) {
      sb.writeln(
        '  ${poll.createdAt.toIso8601String()} — '
        'lean ${poll.lean}, confidence ${poll.confidence.name}'
        '${poll.rationale != null ? ", rationale: ${poll.rationale}" : ""}',
      );
    }
    return sb.toString();
  }

  Map<String, dynamic>? _firstJsonObject(String text) {
    // Whole-text first, then line-by-line as a fallback for chatty models.
    for (final candidate in [text, ...text.split('\n')]) {
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) continue;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        continue;
      }
    }
    return null;
  }
}
