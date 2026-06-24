import 'package:drift/drift.dart';
import '../converters.dart';

@DataClassName('CaseRow')
class Cases extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get question => text()();
  TextColumn get optionA => text()();
  TextColumn get optionB => text()();
  TextColumn get statedCriteria => text().map(const JsonListConverter())();
  TextColumn get stakes => text()();
  TextColumn get regretHorizon => text()();
  TextColumn get category => text().nullable()();
  BoolColumn get communityVisible =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
