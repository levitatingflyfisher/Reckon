import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Native (mobile/desktop) drift executor: a background-isolate
/// [NativeDatabase] over `reckon.sqlite` in the app documents directory. The
/// open is deferred inside a [LazyDatabase] so constructing it never blocks or
/// touches the filesystem until the first query.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'reckon.sqlite'));
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    return NativeDatabase.createInBackground(file);
  });
}
