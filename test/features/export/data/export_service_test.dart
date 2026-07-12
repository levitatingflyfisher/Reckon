import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/export/data/export_service.dart';
import 'package:reckon/features/outside_view/data/outside_view_repository_impl.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';
import 'package:reckon/features/outside_view/domain/entities/outside_view.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('gather carries outside-view citations into the bundle', () async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'c-1',
          createdAt: DateTime.utc(2026, 6, 1),
          status: 'open',
          question: 'Marry now or wait?',
          optionA: 'Wait',
          optionB: 'Marry',
          statedCriteria: const [],
          stakes: 'high',
          regretHorizon: 'years',
        ));

    await OutsideViewRepositoryImpl(db).save(OutsideView(
      id: 'ov-1',
      caseId: 'c-1',
      generatedAt: DateTime.utc(2026, 6, 1),
      baseRateSummary: 'summary',
      referenceClassUsed: 'relationship / marriage',
      uncertaintyLevel: 'low',
      stratificationFactors: const {},
      llmMode: 'private',
      modelVersion: 'gemma-3-1b-it',
      citations: const [
        Citation(author: 'A', title: 'A Study', url: 'https://x'),
      ],
    ));

    final bundle =
        await ExportService(db).gather(now: DateTime.utc(2026, 6, 8));

    final view = bundle.cases.single.outsideView;
    expect(view, isNotNull);
    expect(view!.citations, hasLength(1));
    expect(view.citations.first.title, 'A Study');
    expect(view.citations.first.url, 'https://x');
  });

  test('gather carries model_predictions (duel track record) into the '
      'bundle — W4 F1: restore must not silently destroy them', () async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'c-1',
          createdAt: DateTime.utc(2026, 6, 1),
          status: 'open',
          question: 'Marry now or wait?',
          optionA: 'Wait',
          optionB: 'Marry',
          statedCriteria: const [],
          stakes: 'high',
          regretHorizon: 'years',
        ));
    await db.into(db.modelPredictions).insert(ModelPredictionsCompanion.insert(
          id: 'mp-1',
          caseId: 'c-1',
          modelVersion: 'gemma-3-1b-it',
          kind: 'duelForecast',
          predictedAt: DateTime.utc(2026, 6, 2),
          payload: const {'lean': 70, 'forecasterName': 'The Actuary'},
          score: const Value(0.4),
          scoredAt: Value(DateTime.utc(2026, 6, 9)),
        ));

    final bundle =
        await ExportService(db).gather(now: DateTime.utc(2026, 6, 8));

    final predictions = bundle.cases.single.predictions;
    expect(predictions, hasLength(1));
    expect(predictions.single.id, 'mp-1');
    expect(predictions.single.kind, PredictionKind.duelForecast);
    expect(predictions.single.payload['forecasterName'], 'The Actuary');
    expect(predictions.single.score, 0.4);
  });
}
