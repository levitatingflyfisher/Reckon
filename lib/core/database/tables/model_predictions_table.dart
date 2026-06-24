import 'package:drift/drift.dart';
import '../converters.dart';
import 'cases_table.dart';

/// Log of every structured prediction an LLM has made on a case.
///
/// Populated from the LLM service layer so that a) we can measure each
/// model's calibration once resolutions land, and b) multi-model ensembles
/// in later phases have a shared substrate to write into.
///
/// `kind` is a discriminator: 'outside_view', 'repoll_sentiment',
/// 'reveal_observation', future: 'community_seed'. `payload` is the full
/// model output (JSON). `score` is populated on resolution and is a
/// signed calibration proxy; null until resolved.
@DataClassName('ModelPredictionRow')
class ModelPredictions extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(Cases, #id)();
  TextColumn get modelVersion => text()();
  TextColumn get kind => text()();
  DateTimeColumn get predictedAt => dateTime()();
  TextColumn get payload => text().map(const JsonMapConverter())();
  RealColumn get score => real().nullable()();
  DateTimeColumn get scoredAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
