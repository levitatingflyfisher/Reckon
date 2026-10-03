// Source for `web/drift_worker.js`, compiled against THIS project's exact drift
// (2.21.0) + sqlite3 (3.3.0) so the worker's import surface matches the
// `sqlite3.wasm` binary we ship. The prebuilt worker from the drift release
// bundles a different sqlite3 version, which fails at runtime with
// `LinkError ... Import "dart" "localtime": function import requires a callable`.
//
// Recompile after bumping drift/sqlite3:
//   dart compile js -O2 -o web/drift_worker.js web/drift_worker.dart
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
