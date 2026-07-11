// Platform-selected drift [QueryExecutor] factory.
//
// The database is opened differently per platform:
//   * native (mobile/desktop) — a background-isolate [NativeDatabase] over a
//     file in the app documents directory (needs `dart:io`, `path_provider`,
//     and `sqlite3_flutter_libs`);
//   * web — drift's [WasmDatabase] over `sqlite3.wasm` plus the drift worker
//     shipped in `web/`, persisted in the browser (OPFS, else IndexedDB).
//
// `dart.library.io` is available on the native VM and absent on the web, so the
// compiler picks the matching implementation — and a web build never references
// `dart:io`. Both variants expose `QueryExecutor openConnection()`.
export 'connection_web.dart' if (dart.library.io) 'connection_native.dart';
