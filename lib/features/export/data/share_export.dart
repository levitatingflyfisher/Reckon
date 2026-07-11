// Platform-selected export delivery. The native variant writes the export to a
// temp file and hands it to the OS share sheet (dart:io + path_provider +
// share_plus); the web variant reports that file share/save isn't wired up in
// the browser build yet. `dart.library.io` picks the right file; both expose
// `Future<void> shareExport({content, fileName, subject, text})`.
export 'share_export_web.dart' if (dart.library.io) 'share_export_io.dart';
