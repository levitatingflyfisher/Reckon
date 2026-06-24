import 'package:drift/drift.dart';
import 'cases_table.dart';

@DataClassName('ResolutionRow')
class Resolutions extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(Cases, #id)();
  DateTimeColumn get decidedAt => dateTime()();
  TextColumn get chosenOption => text()();
  DateTimeColumn get resolutionCheckDate => dateTime()();
  IntColumn get satisfactionScore => integer().nullable()();
  TextColumn get reflection => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
