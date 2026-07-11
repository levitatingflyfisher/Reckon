import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/bounty/domain/usecases/import_bounty_responses.dart';
import 'package:reckon/features/case/data/case_repository_impl.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/forecasters/data/forecaster_repository_impl.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';
import 'package:reckon/features/predictions/data/prediction_repository_impl.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';

/// The §9 cabin decision, phrased as a Reckon case (optionB = "buy").
Case _cabinCase() => Case(
      id: 'cabin-case',
      createdAt: DateTime.utc(2026, 7, 11),
      deadline: DateTime.utc(2026, 7, 18),
      status: CaseStatus.open,
      question: 'Buy the vacation cabin?',
      optionA: 'Keep renting each summer',
      optionB: 'Buy the cabin',
      statedCriteria: const [],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      category: 'housing',
    );

/// A conforming multi response: [pBuy] is the probability on optionB
/// ("Buy the cabin"), so the imported lean is `round(100 * pBuy)`.
String _response(
  String botName,
  double pBuy, {
  String? requestId = 'cabin-case',
  String? createdAt = '2026-07-11T07:02:00Z',
  String? model,
}) =>
    '{"reckonbounty": "0.1", "kind": "response", '
    '${requestId == null ? '' : '"request_id": "$requestId", '}'
    '"id": "resp-$botName", '
    '${createdAt == null ? '' : '"created_at": "$createdAt", '}'
    '"bot": {"name": "$botName"'
    '${model == null ? '' : ', "model": "$model"'}}, '
    '"forecast": {"distribution": {"Buy the cabin": $pBuy, '
    '"Keep renting each summer": ${1 - pBuy}}, '
    '"rationale": "$botName reasoning"}}';

void main() {
  late AppDatabase db;
  late ForecasterRepositoryImpl forecasters;
  late PredictionRepositoryImpl predictions;
  late ImportBountyResponses import;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    forecasters =
        ForecasterRepositoryImpl(db, now: () => DateTime.utc(2026, 7, 11));
    predictions = PredictionRepositoryImpl(db);
    import = ImportBountyResponses(
      forecasters,
      predictions,
      now: () => DateTime.utc(2026, 7, 12),
    );
    // ModelPredictions.caseId is a real FK — the case must exist.
    await CaseRepositoryImpl(db).insert(_cabinCase());
  });

  tearDown(() => db.close());

  Future<List<ModelPrediction>> duelRows() async =>
      (await predictions.forCase('cabin-case'))
          .where((p) => p.kind == PredictionKind.duelForecast)
          .toList();

  test('imports responses: bots join the roster, forecasts are sealed',
      () async {
    final result = await import(
      _cabinCase(),
      '[${_response("hustlerBot80000", 0.35, model: "llamafile/Qwen2.5-7B")}, '
      '${_response("cautiousBot", 0.20)}]',
    );

    expect(result.imported, 2);
    expect(result.duplicates, 0);
    expect(result.rejected, isEmpty);

    final roster = await forecasters.all();
    final hustler =
        roster.singleWhere((f) => f.id == 'bounty:hustlerBot80000');
    expect(hustler.kind, ForecasterKind.bountyBot);
    expect(hustler.displayName, 'hustlerBot80000');
    expect(hustler.config['model'], 'llamafile/Qwen2.5-7B');

    final rows = await duelRows();
    expect(rows, hasLength(2));
    final hustlerRow = rows.singleWhere(
        (p) => p.payload['forecasterId'] == 'bounty:hustlerBot80000');
    expect(hustlerRow.payload['lean'], 35); // p(optionB) = 0.35
    expect(hustlerRow.payload['forecasterName'], 'hustlerBot80000');
    expect(hustlerRow.payload['source'], 'bounty');
    expect(hustlerRow.payload['rationale'], contains('reasoning'));
    expect(hustlerRow.score, isNull); // sealed, unscored until resolution
  });

  test('imported forecasts score at resolution exactly like duelists — '
      'the §9 ordering comes out', () async {
    await import(
      _cabinCase(),
      '[${_response("hustlerBot80000", 0.35)}, '
      '${_response("cautiousBot", 0.20)}]',
    );

    // §9 resolution: did not buy (chose option A), no regret (+2).
    await predictions.scoreDuelForecasts(
      'cabin-case',
      chosenOption: 'a',
      satisfaction: 2,
      scoredAt: DateTime.utc(2027, 8, 2),
    );

    final rows = await duelRows();
    final hustler = rows.singleWhere(
        (p) => p.payload['forecasterId'] == 'bounty:hustlerBot80000');
    final cautious = rows.singleWhere(
        (p) => p.payload['forecasterId'] == 'bounty:cautiousBot');

    // alignment × satisfaction/2: (2·0.65−1)·1 and (2·0.80−1)·1.
    expect(hustler.score, closeTo(0.30, 1e-9));
    expect(cautious.score, closeTo(0.60, 1e-9));
    // Same winner as the spec's Brier table: cautiousBot earns the
    // reputation (Brier 0.0400 beats 0.1225).
    expect(cautious.score!, greaterThan(hustler.score!));
  });

  test('a second paste of the same responses is idempotent', () async {
    final raw = '[${_response("hustlerBot80000", 0.35)}, '
        '${_response("cautiousBot", 0.20)}]';
    await import(_cabinCase(), raw);
    final second = await import(_cabinCase(), raw);

    expect(second.imported, 0);
    expect(second.duplicates, 2);
    expect(await duelRows(), hasLength(2));
    expect((await forecasters.all()).where((f) => f.id.startsWith('bounty:')),
        hasLength(2));
  });

  test('an existing forecaster row is never clobbered by an import',
      () async {
    await forecasters.upsert(Forecaster(
      id: 'bounty:cautiousBot',
      displayName: 'Cautious (my rename)',
      kind: ForecasterKind.bountyBot,
      enabled: false,
      createdAt: DateTime.utc(2026, 1, 1),
    ));

    final result =
        await import(_cabinCase(), _response('cautiousBot', 0.20));

    expect(result.imported, 1); // the forecast itself is new
    final row = (await forecasters.all())
        .singleWhere((f) => f.id == 'bounty:cautiousBot');
    expect(row.displayName, 'Cautious (my rename)'); // roster is the user's
    expect(row.enabled, isFalse);
  });

  test('a response answering a different request is rejected by name',
      () async {
    final result = await import(
      _cabinCase(),
      _response('hustlerBot80000', 0.35, requestId: 'some-other-case'),
    );

    expect(result.imported, 0);
    expect(result.rejected.single, contains('hustlerBot80000'));
    expect(result.rejected.single, contains('different request'));
    expect(await duelRows(), isEmpty);
  });

  test('a response without a request_id is taken on the user\'s word',
      () async {
    final result = await import(
        _cabinCase(), _response('handWrittenBot', 0.5, requestId: null));

    expect(result.imported, 1);
  });

  test('a response created after the reply-by deadline is excluded',
      () async {
    final result = await import(
      _cabinCase(),
      _response('lateBot', 0.9, createdAt: '2026-07-19T00:00:00Z'),
    );

    expect(result.imported, 0);
    expect(result.rejected.single, contains('lateBot'));
    expect(await duelRows(), isEmpty);
  });

  test('several responses from one bot: the latest one wins', () async {
    final result = await import(
      _cabinCase(),
      '[${_response("hustlerBot80000", 0.35, createdAt: "2026-07-11T07:02:00Z")}, '
      '${_response("hustlerBot80000", 0.45, createdAt: "2026-07-12T09:00:00Z")}]',
    );

    expect(result.imported, 1);
    final row = (await duelRows()).single;
    expect(row.payload['lean'], 45);
  });

  test(
      'one combined answers file, two requests: the response to the OTHER '
      'request must not knock out this case\'s valid one', () async {
    // Bot X answered both cases; the other case's answer is newer, so a
    // botName-keyed dedup run before the request gate would keep only the
    // rejected one and import nothing.
    final result = await import(
      _cabinCase(),
      '[${_response("botX", 0.35, createdAt: "2026-07-11T07:02:00Z")}, '
      '${_response("botX", 0.90, requestId: "some-other-case", createdAt: "2026-07-12T09:00:00Z")}]',
    );

    expect(result.imported, 1);
    expect(result.rejected.single, contains('different request'));
    expect((await duelRows()).single.payload['lean'], 35);
  });

  test(
      'a post-deadline revision must not knock out the pre-deadline answer — '
      'the latest created_at BEFORE reply_by wins (§3.2)', () async {
    final result = await import(
      _cabinCase(),
      '[${_response("botX", 0.35, createdAt: "2026-07-11T10:00:00Z")}, '
      '${_response("botX", 0.90, createdAt: "2026-07-19T20:00:00Z")}]',
    );

    expect(result.imported, 1);
    expect(result.rejected.single, contains('deadline'));
    expect((await duelRows()).single.payload['lean'], 35);
  });

  test('an untimestamped response never replaces a timestamped one',
      () async {
    final result = await import(
      _cabinCase(),
      '[${_response("botX", 0.80, createdAt: "2026-07-11T09:00:00Z")}, '
      '${_response("botX", 0.50, createdAt: null)}]',
    );

    expect(result.imported, 1);
    expect((await duelRows()).single.payload['lean'], 80,
        reason: 'the documented rule is latest created_at wins — a stray '
            'entry with no timestamp cannot be "later"');
  });

  test('an unmatchable distribution rejects that response, imports the rest',
      () async {
    final result = await import(
      _cabinCase(),
      '[${_response("cautiousBot", 0.20)}, '
      '{"reckonbounty": "0.1", "kind": "response", "bot": {"name": "yesNoBot"}, '
      '"forecast": {"distribution": {"yes": 0.7, "no": 0.3}}}]',
    );

    expect(result.imported, 1);
    expect(result.rejected.single, contains('yesNoBot'));
    expect((await duelRows()).single.payload['forecasterId'],
        'bounty:cautiousBot');
  });

  test('a bare binary p is rejected, never guessed onto an option', () async {
    // The spec's own §3.2 worked response: p = 0.35 with no option named.
    final result = await import(
      _cabinCase(),
      '{"reckonbounty": "0.1", "kind": "response", '
      '"request_id": "cabin-case", "id": "resp-p", '
      '"created_at": "2026-07-11T07:02:00Z", '
      '"bot": {"name": "hustlerBot80000"}, '
      '"forecast": {"p": 0.35, "rationale": "r"}}',
    );

    expect(result.imported, 0);
    expect(result.rejected.single, contains('hustlerBot80000'));
    expect(result.rejected.single, contains('distribution'));
    expect(await duelRows(), isEmpty,
        reason: 'a forecast whose orientation is a guess must never be '
            'sealed into the record');
  });

  test('a malformed paste throws the codec\'s precise FormatException',
      () async {
    expect(
      () => import(_cabinCase(), '{"reckonbounty": "0.1"}'),
      throwsA(isA<FormatException>()),
    );
    expect(await duelRows(), isEmpty);
  });
}
