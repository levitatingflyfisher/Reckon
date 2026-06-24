import 'package:drift/drift.dart';
import '../converters.dart';

@DataClassName('ReferenceClassRow')
class ReferenceClasses extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get subcategory => text()();
  TextColumn get baseRateDescription => text()();
  TextColumn get stratificationVariables =>
      text().map(const JsonListConverter())();
  TextColumn get sources => text().map(const JsonListConverter())();
  TextColumn get commonCriteria => text().map(const JsonListConverter())();
  TextColumn get commonRegretPatterns => text()();
  TextColumn get uncertaintyLevel => text()();
  TextColumn get lastUpdated => text()();

  @override
  Set<Column> get primaryKey => {id};
}
