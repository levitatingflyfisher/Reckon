import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/forecaster.dart';
import '../domain/repositories/forecaster_repository.dart';

/// Drift-backed [ForecasterRepository]. The default persona roster is created
/// lazily on first read (never by a migration) so upgraded and fresh installs
/// behave identically, and so an intentionally emptied roster stays empty
/// only until the next read — while a *pruned* one is respected forever
/// (the seed gate is "table empty", not "defaults missing").
class ForecasterRepositoryImpl implements ForecasterRepository {
  ForecasterRepositoryImpl(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  static const _defaults = [
    (
      id: 'persona-base-rate-skeptic',
      displayName: 'Base-rate skeptic',
      persona: 'Anchors on how decisions like this usually turn out for '
          'people in general, and distrusts the story that makes this case '
          'feel special.',
    ),
    (
      id: 'persona-steelman-advocate',
      displayName: 'Steelman advocate',
      persona: 'Makes the strongest honest case for the option the asker '
          'seems to be leaning away from before settling on a lean.',
    ),
  ];

  @override
  Future<List<Forecaster>> all() async {
    await ensureDefaults();
    final rows = await (_db.select(_db.forecasters)
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.displayName),
          ]))
        .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<Forecaster>> enabled() async {
    final roster = await all();
    return roster.where((f) => f.enabled).toList();
  }

  @override
  Future<void> upsert(Forecaster f) async {
    await _db.into(_db.forecasters).insertOnConflictUpdate(
          ForecastersCompanion.insert(
            id: f.id,
            displayName: f.displayName,
            kind: f.kind.name,
            configJson: f.config,
            enabled: Value(f.enabled),
            createdAt: f.createdAt,
          ),
        );
  }

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    await (_db.update(_db.forecasters)..where((t) => t.id.equals(id)))
        .write(ForecastersCompanion(enabled: Value(enabled)));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.forecasters)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> ensureDefaults() async {
    final any =
        await (_db.select(_db.forecasters)..limit(1)).getSingleOrNull();
    if (any != null) return;
    final createdAt = _now();
    for (final d in _defaults) {
      await _db.into(_db.forecasters).insert(
            ForecastersCompanion.insert(
              id: d.id,
              displayName: d.displayName,
              kind: ForecasterKind.persona.name,
              configJson: {'persona': d.persona},
              createdAt: createdAt,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Forecaster _toEntity(ForecasterRow r) => Forecaster(
        id: r.id,
        displayName: r.displayName,
        kind: ForecasterKind.values.firstWhere(
          (k) => k.name == r.kind,
          orElse: () => ForecasterKind.persona,
        ),
        config: r.configJson,
        enabled: r.enabled,
        createdAt: r.createdAt,
      );
}
