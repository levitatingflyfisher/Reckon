import 'package:drift/drift.dart';

@DataClassName('UserProfileRow')
class UserProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get sesBracket => text().nullable()();
  TextColumn get religiosity => text().nullable()();
  TextColumn get relationshipStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
