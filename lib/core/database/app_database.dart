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
import 'tables/forecasters_table.dart';
import 'tables/groups_table.dart';
import 'tables/group_members_table.dart';

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
  Forecasters,
  Groups,
  GroupMembers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 5;

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
          if (from < 5) {
            // Forecaster registry + persistent groups. Tables first: the new
            // parties.group_id column references groups.
            await m.createTable(forecasters);
            await m.createTable(groups);
            await m.createTable(groupMembers);
            if (from >= 3) {
              // Databases older than v3 get parties/party_ballots freshly
              // created above (from < 3) already in their v5 shape — only
              // the v3/v4 shape needs the new columns added.
              await m.addColumn(parties, parties.groupId);
              await m.addColumn(parties, parties.considered);
              await m.addColumn(partyBallots, partyBallots.memberId);
            }
          }
        },
        beforeOpen: (details) async {
          // Enforce referential integrity (off by default in SQLite). All
          // child tables reference Cases; this prevents orphaned rows.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
