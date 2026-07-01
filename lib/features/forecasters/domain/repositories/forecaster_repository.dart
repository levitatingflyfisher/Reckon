import '../entities/forecaster.dart';

/// The forecaster roster. Reads are lazy-seeding: the first read of an empty
/// roster installs the two default persona forecasters (see
/// [ensureDefaults]), so a fresh install always has someone to duel without
/// any migration-time seeding.
abstract class ForecasterRepository {
  /// Every forecaster, seeded if empty, ordered by creation time.
  Future<List<Forecaster>> all();

  /// Only forecasters currently allowed to duel, seeded if empty.
  Future<List<Forecaster>> enabled();

  /// Insert, or fully replace the row with the same id.
  Future<void> upsert(Forecaster forecaster);

  /// Flip participation without touching config or history.
  Future<void> setEnabled(String id, bool enabled);

  /// Remove a forecaster. Its logged predictions (and their scores) remain —
  /// the record is append-only.
  Future<void> delete(String id);

  /// Install the default persona roster if — and only if — the table is
  /// empty. A pruned roster is never re-seeded: the roster is the user's.
  Future<void> ensureDefaults();
}
