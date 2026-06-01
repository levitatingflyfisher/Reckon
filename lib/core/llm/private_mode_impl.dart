import 'dart:async';
import 'dart:convert';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../../features/case/domain/entities/case.dart';
import '../../features/outside_view/domain/entities/reference_class_entry.dart';
import '../../features/outside_view/domain/entities/user_profile.dart';
import '../../features/reveal/domain/entities/case_time_series.dart';
import '../../features/reveal/domain/entities/reveal_observation.dart';
import 'llm_prompts.dart';
import 'llm_service.dart';

/// On-device LLM implementation using flutter_gemma (Gemma 3 1B IT).
///
/// Error policy: inference failures produce recoverable sentinel values
/// (empty streams, fallback text). The app never crashes on a model hiccup.
class PrivateModeImpl implements LlmService {
  PrivateModeImpl(this._model, this._modelVersion);

  final InferenceModel _model;

  /// Identifier of the active [ReckonModelSpec] — stamped into every
  /// structured output so the prediction log attributes work to the right
  /// model when multiple are available.
  final String _modelVersion;

  @override
  String get modelVersion => _modelVersion;

  // ---------------------------------------------------------------------------
  // LlmService — conductIntake
  // ---------------------------------------------------------------------------

  @override
  Stream<String> conductIntake(IntakeContext ctx) async* {
    final chat = await _model.createChat(
      systemInstruction: LlmPrompts.intakeInterviewer,
      temperature: 0.7,
      topK: 40,
    );

    // Replay only the most recent turns. A small model's context is tiny, so
    // feeding an ever-growing transcript is what made it run out of room and
    // go silent after a couple of exchanges. The last dozen turns are plenty
    // for a four-question intake and keep us well inside maxTokens.
    const maxReplayTurns = 12;
    final recent = ctx.transcript.length > maxReplayTurns
        ? ctx.transcript.sublist(ctx.transcript.length - maxReplayTurns)
        : ctx.transcript;
    for (final turn in recent) {
      if (turn.content.isEmpty) continue;
      await chat.addQueryChunk(Message.text(
        text: turn.content,
        isUser: turn.role == IntakeRole.user,
      ));
    }

    if (ctx.userInput.isNotEmpty) {
      await chat.addQueryChunk(Message.text(
        text: ctx.userInput,
        isUser: true,
      ));
    }

    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LlmService — synthesizeOutsideView
  // ---------------------------------------------------------------------------

  @override
  Future<OutsideViewResult> synthesizeOutsideView(
    Case case_,
    ReferenceClassEntry ref,
    UserProfile profile,
  ) async {
    try {
      final prompt = _buildOutsideViewPrompt(case_, ref, profile);
      final text = await _generateBlocking(
        LlmPrompts.outsideViewSynthesizer,
        prompt,
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
            'Unable to generate outside view — model inference failed.',
        referenceClassUsed: '${ref.category} / ${ref.subcategory}',
        uncertaintyLevel: 'unknown',
        stratificationFactors: const {},
        modelVersion: _modelVersion,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LlmService — detectRepollSentiment
  // ---------------------------------------------------------------------------

  @override
  Future<MismatchResult> detectRepollSentiment(
      int lean, String rationale) async {
    try {
      final prompt = 'Lean score: $lean\nRationale: $rationale';
      final text = await _generateBlocking(
        LlmPrompts.repollSentimentDetector,
        prompt,
      );

      final json = _firstJsonLine(text);
      if (json != null) {
        return MismatchResult(
          mismatch: json['mismatch'] as bool? ?? false,
          observation: json['observation'] as String? ?? '',
        );
      }

      // Model returned text but no parseable JSON — treat as no mismatch.
      return const MismatchResult(mismatch: false, observation: '');
    } catch (_) {
      return const MismatchResult(mismatch: false, observation: '');
    }
  }

  // ---------------------------------------------------------------------------
  // LlmService — generateRevealObservation
  // ---------------------------------------------------------------------------

  @override
  Future<RevealObservation> generateRevealObservation(
    CaseTimeSeries timeSeries,
  ) async {
    try {
      final prompt = _buildRevealPrompt(timeSeries);
      final text = await _generateBlocking(
        LlmPrompts.revealObservation,
        prompt,
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
        text: 'Unable to generate observation — model inference failed.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LlmService — generateCommunitySeed (Phase 3)
  // ---------------------------------------------------------------------------

  @override
  Future<CommunitySeed> generateCommunitySeed(Case case_) =>
      throw UnimplementedError('Community seed — Phase 3');

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Runs a single prompt through a fresh chat session and collects the
  /// full response as a concatenated string.
  Future<String> _generateBlocking(
    String systemInstruction,
    String userMessage,
  ) async {
    final chat = await _model.createChat(
      systemInstruction: systemInstruction,
      temperature: 0.4,
      topK: 20,
    );

    await chat.addQueryChunk(Message.text(
      text: userMessage,
      isUser: true,
    ));

    final buffer = StringBuffer();
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        buffer.write(response.token);
      }
    }
    return buffer.toString();
  }

  /// Builds the user-facing prompt for the outside-view synthesizer.
  String _buildOutsideViewPrompt(
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

  /// Builds the user-facing prompt for reveal observation.
  String _buildRevealPrompt(CaseTimeSeries timeSeries) {
    final sb = StringBuffer()
      ..writeln('DECISION TIME SERIES')
      ..writeln('Category: ${timeSeries.category}')
      ..writeln(
          'Deadline: ${timeSeries.deadline?.toIso8601String() ?? "none"}')
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

  /// Extracts the first line of [text] that parses as JSON.
  /// Returns `null` if no JSON line is found.
  Map<String, dynamic>? _firstJsonLine(String text) {
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } on FormatException {
        continue;
      }
    }
    return null;
  }
}
