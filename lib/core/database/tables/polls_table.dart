import 'package:drift/drift.dart';
import 'cases_table.dart';

@DataClassName('PollRow')
class Polls extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(Cases, #id)();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get pollNumber => integer()();
  IntColumn get lean => integer()();
  TextColumn get rationale => text().nullable()();
  TextColumn get confidence => text()();
  BoolColumn get revealed =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
