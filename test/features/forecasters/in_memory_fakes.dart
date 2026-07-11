import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';
import 'package:reckon/features/forecasters/domain/repositories/forecaster_repository.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';

/// Widget tests use these instead of a live drift DB: queries issued during
/// widget build never resolve under the widget tester's fake clock (the
/// spinner pumps forever and `db.close()` then hangs teardown). Persistence
/// itself is covered by the repository/usecase unit tests.
class InMemoryForecasterRepository implements ForecasterRepository {
  InMemoryForecasterRepository([List<Forecaster>? seed])
      : roster = [...?seed];

  final List<Forecaster> roster;

  @override
  Future<List<Forecaster>> all() async => List.unmodifiable(roster);

  @override
  Future<List<Forecaster>> enabled() async =>
      roster.where((f) => f.enabled).toList();

  @override
  Future<void> upsert(Forecaster forecaster) async {
    roster
      ..removeWhere((f) => f.id == forecaster.id)
      ..add(forecaster);
  }

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    final i = roster.indexWhere((f) => f.id == id);
    if (i >= 0) roster[i] = roster[i].copyWith(enabled: enabled);
  }

  @override
  Future<void> delete(String id) async =>
      roster.removeWhere((f) => f.id == id);

  @override
  Future<void> ensureDefaults() async {}
}

class InMemoryPredictionRepository implements PredictionRepository {
  final List<ModelPrediction> logged = [];

  @override
  Future<void> log(ModelPrediction p) async => logged.add(p);

  @override
  Future<List<ModelPrediction>> forCase(String caseId) async =>
      logged.where((p) => p.caseId == caseId).toList();

  @override
  Future<void> scoreForCase(String caseId,
      {required double score, required DateTime scoredAt}) async {}

  @override
  Future<List<ModelScorecardEntry>> scorecard() async => const [];
}
