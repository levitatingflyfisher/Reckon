import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web drift executor: drift's [WasmDatabase] over the `sqlite3.wasm` binary
/// and `drift_worker.js` shipped in `web/`. drift probes the browser and picks
/// the most durable storage backend available (OPFS, else IndexedDB), falling
/// back to in-memory only when the browser supports nothing persistent.
///
/// The open is deferred inside a [LazyDatabase] so constructing it never blocks
/// startup. `resolvedExecutor` is a `DatabaseConnection`, which implements
/// [QueryExecutor], so it drops straight into [LazyDatabase].
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'reckon',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
