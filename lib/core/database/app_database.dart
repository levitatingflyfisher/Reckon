import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'converters.dart';
import 'tables/cases_table.dart';
import 'tables/polls_table.dart';
import 'tables/resolutions_table.dart';
import 'tables/outside_views_table.dart';
import 'tables/reference_classes_table.dart';
import 'tables/user_profile_table.dart';
import 'tables/community_forecasts_table.dart';
import 'tables/model_predictions_table.dart';
import 'tables/parties_table.dart';
import 'tables/party_ballots_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Cases,
  Polls,
  Resolutions,
  OutsideViews,
  ReferenceClasses,
  UserProfile,
  CommunityForecasts,
  ModelPredictions,
  Parties,
  PartyBallots,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(userProfile).insert(
            UserProfileCompanion.insert(id: const Value(1)),
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(modelPredictions);
          }
          if (from < 3) {
            await m.createTable(parties);
            await m.createTable(partyBallots);
          }
          if (from < 4) {
            await m.addColumn(outsideViews, outsideViews.citations);
          }
        },
        beforeOpen: (details) async {
          // Enforce referential integrity (off by default in SQLite). All
          // child tables reference Cases; this prevents orphaned rows.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
