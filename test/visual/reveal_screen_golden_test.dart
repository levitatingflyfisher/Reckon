import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';
import 'package:reckon/features/reveal/data/reveal_providers.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';
import 'package:reckon/features/reveal/domain/usecases/generate_reveal.dart';
import 'package:reckon/features/reveal/presentation/reveal_screen.dart';

import 'visual_golden_helper.dart';

const _caseId = 'case-reveal-golden';

final _sampleCase = Case(
  id: _caseId,
  createdAt: DateTime.utc(2026, 4, 1),
  deadline: null,
  status: CaseStatus.open,
  question: 'Move cities or stay?',
  optionA: 'Stay',
  optionB: 'Move',
  statedCriteria: const [],
  stakes: Stakes.high,
  regretHorizon: RegretHorizon.years,
  category: 'relocation',
);

// Four polls drifting from "Stay" (low lean) toward "Move" (high lean).
final _samplePolls = <Poll>[
  for (var i = 0; i < 4; i++)
    Poll(
      id: 'poll-$i',
      caseId: _caseId,
      createdAt: DateTime.utc(2026, 4, 1 + i),
      pollNumber: i + 1,
      lean: [20, 45, 60, 80][i],
      confidence: Confidence.medium,
      rationale: 'Reflection note for poll ${i + 1}.',
    ),
];

void main() {
  testWidgets('RevealScreen chart + observation golden', (tester) async {
    // Family providers overridden directly — no NativeDatabase on the render
    // path (its background-isolate I/O never completes under fake async).
    await goldenAtSizes(
      tester,
      name: 'reveal_screen',
      theme: OhTheme.light(),
      home: ProviderScope(
        overrides: [
          caseByIdProvider.overrideWith((ref, id) async => _sampleCase),
          pollsForCaseProvider.overrideWith((ref, id) async => _samplePolls),
          generateRevealProvider.overrideWith(
            (ref) async => GenerateReveal(_FakeLlm(), _FakePredictions()),
          ),
        ],
        child: const RevealScreen(caseId: _caseId),
      ),
      // The screen shows a CircularProgressIndicator (infinite ticker) until
      // _prepare() lands, and fl_chart runs an entry animation — pumpAndSettle
      // would never return. Bounded pumps capture the settled chart + text.
      settle: false,
      pumpDuration: const Duration(seconds: 2),
      sizes: const <String, Size>{
        'phone': Size(360, 800),
        'narrow': Size(320, 800),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });
}

class _FakeLlm implements LlmService {
  @override
  String get modelVersion => 'gemma-3-1b-it';

  @override
  Stream<String> conductIntake(IntakeContext ctx) => const Stream.empty();

  @override
  Future<OutsideViewResult> synthesizeOutsideView(
    Case c,
    ReferenceClassEntry r,
    UserProfile p,
  ) =>
      throw UnimplementedError();

  @override
  Future<MismatchResult> detectRepollSentiment(int lean, String rationale) =>
      throw UnimplementedError();

  @override
  Future<RevealObservation> generateRevealObservation(
    CaseTimeSeries ts,
  ) async =>
      const RevealObservation(
        text:
            'Your lean drifted steadily toward Move across four polls — not a '
            'single dramatic swing, but a slow, consistent settling.',
      );

  @override
  Future<CommunitySeed> generateCommunitySeed(Case c) =>
      throw UnimplementedError();
}

class _FakePredictions implements PredictionRepository {
  @override
  Future<void> log(ModelPrediction p) async {}

  @override
  Future<List<ModelPrediction>> forCase(String caseId) async => [];

  @override
  Future<void> scoreForCase(
    String caseId, {
    required double score,
    required DateTime scoredAt,
  }) async {}

  @override
  Future<List<ModelScorecardEntry>> scorecard() async => [];
}
