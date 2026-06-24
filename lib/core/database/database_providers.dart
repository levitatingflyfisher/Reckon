import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'seed/reference_class_seeder.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final seedReferenceClassesProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await ReferenceClassSeeder(db).seedFromAsset();
});
