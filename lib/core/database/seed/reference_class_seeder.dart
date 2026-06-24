import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../app_database.dart';

class ReferenceClassSeeder {
  ReferenceClassSeeder(this._db);

  final AppDatabase _db;
  static const _assetPath = 'assets/reference_classes.json';

  Future<void> seedFromAsset() async {
    if (await hasBeenSeeded()) return;
    final jsonStr = await rootBundle.loadString(_assetPath);
    await seedFromJsonString(jsonStr);
  }

  Future<void> seedFromJsonString(String jsonStr) async {
    final entries = jsonDecode(jsonStr) as List<dynamic>;
    await _db.batch((batch) {
      for (final raw in entries) {
        final entry = raw as Map<String, dynamic>;
        batch.insert(
          _db.referenceClasses,
          ReferenceClassesCompanion.insert(
            id: entry['id'] as String,
            category: entry['category'] as String,
            subcategory: entry['subcategory'] as String,
            baseRateDescription: entry['base_rate_description'] as String,
            stratificationVariables:
                (entry['stratification_variables'] as List).cast<dynamic>(),
            sources: (entry['sources'] as List).cast<dynamic>(),
            commonCriteria: (entry['common_criteria'] as List).cast<dynamic>(),
            commonRegretPatterns: entry['common_regret_patterns'] as String,
            uncertaintyLevel: entry['uncertainty_level'] as String,
            lastUpdated: entry['last_updated'] as String,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<bool> hasBeenSeeded() async {
    final count = await _db
        .customSelect('SELECT COUNT(*) AS c FROM reference_classes')
        .getSingle();
    return (count.data['c'] as int) > 0;
  }
}
