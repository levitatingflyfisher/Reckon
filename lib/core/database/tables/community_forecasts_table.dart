import 'package:drift/drift.dart';

@DataClassName('CommunityForecastRow')
class CommunityForecasts extends Table {
  TextColumn get id => text()();

  @override
  Set<Column> get primaryKey => {id};
}
