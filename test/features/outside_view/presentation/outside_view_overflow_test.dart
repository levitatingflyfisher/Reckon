import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

const _caseId = 'case-overflow';

final _case = Case(
  id: _caseId,
  createdAt: DateTime.utc(2026, 6, 1),
  deadline: null,
  status: CaseStatus.open,
  question: 'q',
  optionA: 'a',
  optionB: 'b',
  statedCriteria: const [],
  stakes: Stakes.high,
  regretHorizon: RegretHorizon.years,
  category: 'career',
);

final _view = OutsideView(
  id: 'ov-overflow',
  caseId: _caseId,
  generatedAt: DateTime.utc(2026, 6, 1),
  baseRateSummary:
      'A deliberately long base-rate summary that, at a large accessibility '
      'text scale on a narrow phone, is taller than the viewport and must '
      'scroll rather than overflow the column behind the pinned action button.',
  referenceClassUsed: 'career / role change',
  uncertaintyLevel: 'medium',
  stratificationFactors: const {},
  llmMode: 'private',
  modelVersion: 'gemma-3-1b-it',
  citations: const [
    Citation(author: 'BLS', title: 'Employee Tenure', url: 'https://bls.gov'),
  ],
);

/// Regression guard: a long Outside View at 320dp / ×3 must scroll, not
/// overflow the column behind the pinned button. Family providers are
/// overridden directly (no NativeDatabase, which would hang under fake async).
void main() {
  testWidgets(
      'OutsideViewScreen scrolls instead of overflowing at 320dp / ×3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        caseByIdProvider.overrideWith((ref, id) async => _case),
        outsideViewForCaseProvider.overrideWith((ref, id) async => _view),
        getOutsideViewProvider.overrideWith((ref) async => GetOutsideView(
              _FakeRepo(_view),
              _FakeLlm(),
              _FakePredictions(),
            )),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(3.0)),
          child: child!,
        ),
        home: const OutsideViewScreen(caseId: _caseId),
      ),
    ));
    // Drain the post-frame _generate() + provider reads without pumpAndSettle
    // (the screen shows a progress indicator before data lands).
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}

class _FakeRepo implements OutsideViewRepository {
  _FakeRepo(this._view);
  final OutsideView _view;
  @override
  Future<void> save(OutsideView view) async {}
  @override
  Future<OutsideView?> getForCase(String caseId) async => _view;
  @override
  Future<ReferenceClassEntry?> findReferenceClass(String category) async =>
      const ReferenceClassEntry(
        id: 'r',
        category: 'career',
        subcategory: 's',
        baseRateDescription: 'd',
        stratificationVariables: [],
        sources: [],
        commonCriteria: [],
        commonRegretPatterns: 'p',
        uncertaintyLevel: 'medium',
        lastUpdated: '2026-01-01',
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
          Case c, ReferenceClassEntry r, UserProfile p) async =>
      const OutsideViewResult(
        baseRateSummary: 's',
        referenceClassUsed: 'career / role change',
        uncertaintyLevel: 'medium',
        stratificationFactors: {},
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
  Future<void> scoreForCase(String caseId,
      {required double score, required DateTime scoredAt}) async {}
  @override
  Future<List<ModelScorecardEntry>> scorecard() async => [];
}
