import 'package:drift/drift.dart';
import '../converters.dart';
import 'cases_table.dart';

@DataClassName('OutsideViewRow')
class OutsideViews extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(Cases, #id)();
  DateTimeColumn get generatedAt => dateTime()();
  TextColumn get baseRateSummary => text()();
  TextColumn get referenceClassUsed => text()();
  TextColumn get uncertaintyLevel => text()();
  TextColumn get stratificationFactors =>
      text().map(const JsonMapConverter())();
  TextColumn get llmMode => text()();
  TextColumn get modelVersion => text()();

  /// Curated literature citations ([{author, title, url}]) snapshotted from the
  /// reference class at generation time. Nullable: rows written before v3 have
  /// none, and are read back as an empty list.
  TextColumn get citations =>
      text().map(const JsonListConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
