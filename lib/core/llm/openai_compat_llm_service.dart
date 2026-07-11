import 'dart:convert';

import '../../features/case/domain/entities/case.dart';
import '../../features/outside_view/domain/entities/reference_class_entry.dart';
import '../../features/outside_view/domain/entities/user_profile.dart';
import '../../features/reveal/domain/entities/case_time_series.dart';
import '../../features/reveal/domain/entities/reveal_observation.dart';
import 'anthropic_client.dart' show intakeMessages;
import 'llm_prompts.dart';
import 'llm_service.dart';
import 'openai_compat_client.dart';

/// [LlmService] over any OpenAI-compatible chat endpoint (llamafile, Ollama,
/// vLLM…). Mirrors [AnthropicLlmService]: same shared [LlmPrompts], same
/// sentinel-not-throw error policy, so outputs and failure behavior stay
/// consistent across backends. The `{role, content}` message shape is
/// identical to Anthropic's, so the intake transcript mapper is reused.
class OpenAiCompatLlmService implements LlmService {
  OpenAiCompatLlmService(this._client, {String? modelVersion})
      : _modelVersion = modelVersion ?? _client.model;

  final OpenAiCompatClient _client;
  final String _modelVersion;

  @override
  String get modelVersion => _modelVersion;

  @override
  Stream<String> conductIntake(IntakeContext ctx) async* {
    try {
      final text = await _client.createChatCompletion(
        system: LlmPrompts.intakeInterviewer,
        messages: intakeMessages(ctx),
        temperature: 0.7,
      );
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
      final text = await _client.complete(
        LlmPrompts.outsideViewSynthesizer,
        _outsideViewPrompt(case_, ref, profile),
      );
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
      final text = await _client.complete(
        LlmPrompts.repollSentimentDetector,
        'Lean score: $lean\nRationale: $rationale',
      );
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
      final text = await _client.complete(
        LlmPrompts.revealObservation,
        _revealPrompt(timeSeries),
      );
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
      final text = await _client.complete(
        LlmPrompts.forecasterSeed(persona),
        LlmPrompts.decisionBrief(case_),
        temperature: temperature ?? 0.4,
      );
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
      final text = await _client.complete(
        LlmPrompts.redactor,
        'TITLE: $title\nBACKGROUND: $background',
      );
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

  // --- prompt builders (mirror the other backends) ---------------------------

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
    // Whole-text first (hosted models usually return clean JSON), then
    // line-by-line as a fallback for chatty local models.
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
