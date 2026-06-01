import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/outside_view/data/outside_view_providers.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';
import 'package:reckon/features/outside_view/domain/entities/outside_view.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/outside_view/domain/repositories/outside_view_repository.dart';
import 'package:reckon/features/outside_view/domain/usecases/get_outside_view.dart';
import 'package:reckon/features/outside_view/presentation/outside_view_screen.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';

import 'visual_golden_helper.dart';

const _caseId = 'case-golden';

final _sampleCase = Case(
  id: _caseId,
  createdAt: DateTime.utc(2026, 6, 1),
  deadline: null,
  status: CaseStatus.open,
  question: 'Take the new role or stay?',
  optionA: 'Stay',
  optionB: 'Take it',
  statedCriteria: const [],
  stakes: Stakes.high,
  regretHorizon: RegretHorizon.years,
  category: 'career',
);

final _sampleView = OutsideView(
  id: 'ov-golden',
  caseId: _caseId,
  generatedAt: DateTime.utc(2026, 6, 1),
  baseRateSummary:
      'Most people who change roles at a similar career stage report stable '
      'or improved satisfaction within two years; regret concentrates in moves '
      'made primarily to escape rather than toward something.',
  referenceClassUsed: 'career / role change',
  uncertaintyLevel: 'medium',
  stratificationFactors: const {'tenure': '5y'},
  llmMode: 'private',
  modelVersion: 'gemma-3-1b-it',
  citations: const [
    Citation(
      author: 'BLS',
      title: 'Employee Tenure in 2024',
      url: 'https://www.bls.gov/tenure',
    ),
    Citation(author: 'Pew Research', title: 'Unlinked survey', url: ''),
  ],
);

void main() {
  testWidgets('OutsideViewScreen data-state golden', (tester) async {
    // No DB on the render path: the family providers are overridden to return
    // the case + view directly, and getOutsideView is a fake-backed use-case.
    // (A real NativeDatabase.memory() does background-isolate I/O that never
    // completes under flutter_test's fake-async clock, hanging _generate().)
    await goldenAtSizes(
      tester,
      name: 'outside_view_screen',
      theme: OhTheme.light(),
      home: ProviderScope(
        overrides: [
          caseByIdProvider.overrideWith((ref, id) async => _sampleCase),
          outsideViewForCaseProvider
              .overrideWith((ref, id) async => _sampleView),
          getOutsideViewProvider.overrideWith(
            (ref) async => GetOutsideView(
              _FakeOutsideViewRepo(_sampleView),
              _FakeLlm(),
              _FakePredictions(),
            ),
          ),
        ],
        child: const OutsideViewScreen(caseId: _caseId),
      ),
      // _generate() flips a CircularProgressIndicator (infinite ticker) off
      // once the (now synchronous-ish) overrides resolve; bounded pumps clear
      // it without waiting for a settle that never comes.
      settle: false,
      sizes: const <String, Size>{
        'phone': Size(360, 800),
        'narrow': Size(320, 800),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });
}

class _FakeOutsideViewRepo implements OutsideViewRepository {
  _FakeOutsideViewRepo(this._view);
  final OutsideView _view;

  @override
  Future<void> save(OutsideView view) async {}

  @override
  Future<OutsideView?> getForCase(String caseId) async => _view;

  @override
  Future<ReferenceClassEntry?> findReferenceClass(String category) async =>
      const ReferenceClassEntry(
        id: 'career-role-change',
        category: 'career',
        subcategory: 'role change',
        baseRateDescription: 'desc',
        stratificationVariables: ['tenure'],
        sources: [],
        commonCriteria: ['compensation'],
        commonRegretPatterns: 'patterns',
        uncertaintyLevel: 'medium',
        lastUpdated: '2026-04-01',
      );

  @override
  Future<UserProfile> getUserProfile() async => const UserProfile();

  @override
  Future<void> saveUserProfile(UserProfile profile) async {}
}

class _FakeLlm implements LlmService {
  @override
  String get modelVersion => 'gemma-3-1b-it';

  @override
  Stream<String> conductIntake(IntakeContext ctx) => const Stream.empty();

  @override
  Future<OutsideViewResult> synthesizeOutsideView(
    Case case_,
    ReferenceClassEntry ref,
    UserProfile profile,
  ) async =>
      OutsideViewResult(
        baseRateSummary: _sampleView.baseRateSummary,
        referenceClassUsed: _sampleView.referenceClassUsed,
        uncertaintyLevel: _sampleView.uncertaintyLevel,
        stratificationFactors: const {},
        modelVersion: 'gemma-3-1b-it',
      );

  @override
  Future<MismatchResult> detectRepollSentiment(int lean, String rationale) =>
      throw UnimplementedError();

  @override
  Future<RevealObservation> generateRevealObservation(CaseTimeSeries t) =>
      throw UnimplementedError();

  @override
  Future<CommunitySeed> generateCommunitySeed(Case case_) =>
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
