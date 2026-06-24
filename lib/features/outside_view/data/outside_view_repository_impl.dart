import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/citation.dart';
import '../domain/entities/outside_view.dart';
import '../domain/entities/reference_class_entry.dart';
import '../domain/entities/user_profile.dart';
import '../domain/repositories/outside_view_repository.dart';

class OutsideViewRepositoryImpl implements OutsideViewRepository {
  OutsideViewRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> save(OutsideView view) async {
    // One outside view per case: replace any prior row so repeated saves can't
    // accumulate duplicates (the table has no unique constraint on caseId).
    await (_db.delete(_db.outsideViews)
          ..where((t) => t.caseId.equals(view.caseId)))
        .go();
    await _db.into(_db.outsideViews).insert(
          OutsideViewsCompanion.insert(
            id: view.id,
            caseId: view.caseId,
            generatedAt: view.generatedAt,
            baseRateSummary: view.baseRateSummary,
            referenceClassUsed: view.referenceClassUsed,
            uncertaintyLevel: view.uncertaintyLevel,
            stratificationFactors: view.stratificationFactors,
            llmMode: view.llmMode,
            modelVersion: view.modelVersion,
            citations: Value(view.citations.map((c) => c.toJson()).toList()),
          ),
        );
  }

  @override
  Future<OutsideView?> getForCase(String caseId) async {
    final row = await (_db.select(_db.outsideViews)
          ..where((t) => t.caseId.equals(caseId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return OutsideView(
      id: row.id,
      caseId: row.caseId,
      generatedAt: row.generatedAt,
      baseRateSummary: row.baseRateSummary,
      referenceClassUsed: row.referenceClassUsed,
      uncertaintyLevel: row.uncertaintyLevel,
      stratificationFactors: row.stratificationFactors,
      llmMode: row.llmMode,
      modelVersion: row.modelVersion,
      citations: Citation.listFromDynamic(row.citations),
    );
  }

  @override
  Future<ReferenceClassEntry?> findReferenceClass(String category) async {
    // Exact match first, then LIKE fallback, then first available.
    var row = await (_db.select(_db.referenceClasses)
          ..where((t) => t.category.equals(category))
          ..limit(1))
        .getSingleOrNull();
    row ??= await (_db.select(_db.referenceClasses)
          ..where((t) => t.category.like('%$category%'))
          ..limit(1))
        .getSingleOrNull();
    row ??= await (_db.select(_db.referenceClasses)..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return ReferenceClassEntry(
      id: row.id,
      category: row.category,
      subcategory: row.subcategory,
      baseRateDescription: row.baseRateDescription,
      stratificationVariables: row.stratificationVariables.cast<String>(),
      sources: row.sources.cast<Map<String, dynamic>>(),
      commonCriteria: row.commonCriteria.cast<String>(),
      commonRegretPatterns: row.commonRegretPatterns,
      uncertaintyLevel: row.uncertaintyLevel,
      lastUpdated: row.lastUpdated,
    );
  }

  @override
  Future<UserProfile> getUserProfile() async {
    final row = await (_db.select(_db.userProfile)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    return UserProfile(
      sesBracket: row.sesBracket,
      religiosity: row.religiosity,
      relationshipStatus: row.relationshipStatus,
    );
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await (_db.update(_db.userProfile)..where((t) => t.id.equals(1))).write(
      UserProfileCompanion(
        sesBracket: Value(profile.sesBracket),
        religiosity: Value(profile.religiosity),
        relationshipStatus: Value(profile.relationshipStatus),
      ),
    );
  }
}
