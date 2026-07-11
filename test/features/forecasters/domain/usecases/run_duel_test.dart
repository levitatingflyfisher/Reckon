import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/data/case_repository_impl.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/forecasters/data/forecaster_repository_impl.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';
import 'package:reckon/features/forecasters/domain/usecases/run_duel.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/predictions/data/prediction_repository_impl.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';
import 'package:uuid/uuid.dart';

/// Scripted duelist: replies with a fixed seed (recording the persona it was
/// given), or throws, or returns the sentinel.
class _FakeLlm implements LlmService {
  _FakeLlm(this._version, this._seed, {this.throws = false});

  final String _version;
  final CommunitySeed _seed;
  final bool throws;
  final List<String?> personasSeen = [];
  final List<double?> temperaturesSeen = [];

  @override
  String get modelVersion => _version;

  @override
  Future<CommunitySeed> generateCommunitySeed(Case c,
      {String? persona, double? temperature}) async {
    if (throws) throw StateError('backend exploded');
    personasSeen.add(persona);
    temperaturesSeen.add(temperature);
    return _seed;
  }

  @override
  Stream<String> conductIntake(IntakeContext ctx) => const Stream.empty();
  @override
  Future<OutsideViewResult> synthesizeOutsideView(
          Case c, ReferenceClassEntry r, UserProfile p) =>
      throw UnimplementedError();
  @override
  Future<MismatchResult> detectRepollSentiment(int lean, String rationale) =>
      throw UnimplementedError();
  @override
  Future<RevealObservation> generateRevealObservation(CaseTimeSeries ts) =>
      throw UnimplementedError();
  @override
  Future<RedactedQuestion> redactQuestion(
          {required String title, required String background}) =>
      throw UnimplementedError();
}

Case _case([String id = 'c1']) => Case(
      id: id,
      createdAt: DateTime(2026, 7, 11),
      deadline: null,
      status: CaseStatus.open,
      question: 'Move to the cabin?',
      optionA: 'Stay in town',
      optionB: 'Move',
      statedCriteria: const [],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      category: 'relocation',
    );

void main() {
  late AppDatabase db;
  late ForecasterRepositoryImpl forecasters;
  late PredictionRepositoryImpl predictions;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    forecasters = ForecasterRepositoryImpl(db, now: () => DateTime(2026, 7, 11));
    predictions = PredictionRepositoryImpl(db);
    // ModelPredictions.caseId is a real FK — the case must exist.
    await CaseRepositoryImpl(db).insert(_case());
  });

  tearDown(() => db.close());

  RunDuel duel(Future<LlmService?> Function(Forecaster) resolve) => RunDuel(
        forecasters,
        predictions,
        resolve,
        uuid: const Uuid(),
        now: () => DateTime(2026, 7, 11, 22),
      );

  test('logs one sealed forecast per enabled forecaster, persona passed through',
      () async {
    final llm = _FakeLlm(
        'resident', const CommunitySeed(lean: 70, rationale: 'B looks right'));
    final result = await duel((f) async => llm).call(_case());

    // The lazily-seeded roster has the two default personas.
    expect(result.ran, 2);
    expect(result.skipped, 0);
    expect(result.failed, 0);
    expect(llm.personasSeen, hasLength(2));
    expect(llm.personasSeen.every((p) => p != null && p.isNotEmpty), isTrue);

    final rows = await predictions.forCase('c1');
    expect(rows, hasLength(2));
    for (final row in rows) {
      expect(row.kind, PredictionKind.duelForecast);
      expect(row.payload['lean'], 70);
      expect(row.payload['rationale'], 'B looks right');
      expect(row.payload['forecasterId'], startsWith('persona-'));
      expect(row.payload['forecasterName'], isNotEmpty);
      expect(row.modelVersion,
          'resident#${row.payload['forecasterId']}');
      expect(row.score, isNull); // sealed AND unscored until resolution
    }
  });

  test('is idempotent per (case, forecaster) — a second run logs nothing',
      () async {
    final llm =
        _FakeLlm('resident', const CommunitySeed(lean: 60, rationale: 'ok'));
    final d = duel((f) async => llm);

    await d.call(_case());
    final second = await d.call(_case());

    expect(second.ran, 0);
    expect(second.skipped, 2);
    expect(await predictions.forCase('c1'), hasLength(2));
  });

  test('sentinel outputs (empty rationale) are never logged', () async {
    final llm =
        _FakeLlm('resident', const CommunitySeed(lean: 50, rationale: ''));
    final result = await duel((f) async => llm).call(_case());

    expect(result.ran, 0);
    expect(result.failed, 2);
    expect(await predictions.forCase('c1'), isEmpty);
  });

  test('a throwing backend fails that forecaster only — the duel goes on',
      () async {
    final good =
        _FakeLlm('resident', const CommunitySeed(lean: 40, rationale: 'A'));
    final bad = _FakeLlm('resident', const CommunitySeed(lean: 0, rationale: 'x'),
        throws: true);
    final result = await duel((f) async =>
        f.id == 'persona-base-rate-skeptic' ? bad : good).call(_case());

    expect(result.ran, 1);
    expect(result.failed, 1);
    final rows = await predictions.forCase('c1');
    expect(rows, hasLength(1));
    expect(rows.single.payload['forecasterId'], 'persona-steelman-advocate');
  });

  test('unresolvable forecasters (bounty bots, missing keys) are skipped',
      () async {
    final llm =
        _FakeLlm('resident', const CommunitySeed(lean: 55, rationale: 'ok'));
    await forecasters.all(); // seed defaults before adding to the roster
    await forecasters.upsert(Forecaster(
      id: 'bounty:alice-bot',
      displayName: 'alice-bot',
      kind: ForecasterKind.bountyBot,
      createdAt: DateTime(2026, 7, 11),
    ));

    final result = await duel(
            (f) async => f.kind == ForecasterKind.bountyBot ? null : llm)
        .call(_case());

    expect(result.ran, 2);
    expect(result.skipped, 1);
    expect(result.failed, 0);
  });

  test('disabled forecasters sit the duel out entirely', () async {
    final llm =
        _FakeLlm('resident', const CommunitySeed(lean: 55, rationale: 'ok'));
    await forecasters.all(); // seed defaults
    await forecasters.setEnabled('persona-base-rate-skeptic', false);

    final result = await duel((f) async => llm).call(_case());

    expect(result.ran, 1);
    expect(result.skipped, 0);
    final rows = await predictions.forCase('c1');
    expect(rows.single.payload['forecasterId'], 'persona-steelman-advocate');
  });

  test('temperature from forecaster config reaches the backend', () async {
    final llm =
        _FakeLlm('resident', const CommunitySeed(lean: 55, rationale: 'ok'));
    await forecasters.all(); // seed defaults
    await forecasters.upsert(Forecaster(
      id: 'hot-head',
      displayName: 'Hot head',
      kind: ForecasterKind.persona,
      config: const {'persona': 'Goes with the gut.', 'temperature': 0.95},
      createdAt: DateTime(2026, 7, 12),
    ));

    await duel((f) async => llm).call(_case());

    expect(llm.temperaturesSeen, contains(0.95));
  });
}
