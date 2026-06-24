import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/outside_view/domain/entities/outside_view.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/outside_view/domain/repositories/outside_view_repository.dart';
import 'package:reckon/features/outside_view/domain/usecases/get_outside_view.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';

const _refWithSources = ReferenceClassEntry(
  id: 'relationship-marriage',
  category: 'relationship',
  subcategory: 'marriage',
  baseRateDescription: 'desc',
  stratificationVariables: ['age at marriage'],
  sources: [
    {
      'author': 'W. Bradford Wilcox',
      'title': 'Get Married',
      'url': 'https://ifstudies.org',
    },
    {
      'author': 'CDC NSFG',
      'title': 'First Marriages in the US',
      'url': 'https://www.cdc.gov/nchs/nsfg/',
    },
  ],
  commonCriteria: ['shared values'],
  commonRegretPatterns: 'patterns',
  uncertaintyLevel: 'low',
  lastUpdated: '2026-04-01',
);

final _case = Case(
  id: 'c-1',
  createdAt: DateTime.utc(2026, 6, 1),
  deadline: null,
  status: CaseStatus.open,
  question: 'Marry now or wait?',
  optionA: 'Wait',
  optionB: 'Marry',
  statedCriteria: const [],
  stakes: Stakes.high,
  regretHorizon: RegretHorizon.years,
  category: 'relationship',
);

void main() {
  test('carries the reference class sources onto the OutsideView as citations',
      () async {
    final repo = _FakeOutsideViewRepo(_refWithSources);
    final usecase = GetOutsideView(repo, _FakeLlm(), _FakePredictions());

    final view = await usecase(_case);

    expect(view.citations, hasLength(2));
    expect(view.citations[0].author, 'W. Bradford Wilcox');
    expect(view.citations[0].title, 'Get Married');
    expect(view.citations[0].url, 'https://ifstudies.org');
    expect(view.citations[1].author, 'CDC NSFG');

    // The citations are persisted with the record, not just returned.
    expect(repo.saved?.citations, hasLength(2));
  });
}

class _FakeOutsideViewRepo implements OutsideViewRepository {
  _FakeOutsideViewRepo(this._ref);
  final ReferenceClassEntry _ref;
  OutsideView? saved;

  @override
  Future<void> save(OutsideView view) async => saved = view;

  @override
  Future<OutsideView?> getForCase(String caseId) async => saved;

  @override
  Future<ReferenceClassEntry?> findReferenceClass(String category) async =>
      _ref;

  @override
  Future<UserProfile> getUserProfile() async => const UserProfile();

  @override
  Future<void> saveUserProfile(UserProfile profile) async {}
}

class _FakeLlm implements LlmService {
  @override
  String get modelVersion => 'test-model';

  @override
  Future<OutsideViewResult> synthesizeOutsideView(
    Case case_,
    ReferenceClassEntry ref,
    UserProfile profile,
  ) async =>
      const OutsideViewResult(
        baseRateSummary: 'Most marriages in this class endure.',
        referenceClassUsed: 'relationship / marriage',
        uncertaintyLevel: 'low',
        stratificationFactors: {},
        modelVersion: 'test-model',
      );

  @override
  Stream<String> conductIntake(IntakeContext ctx) => const Stream.empty();

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
