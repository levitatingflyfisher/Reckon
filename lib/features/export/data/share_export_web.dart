/// Web: saving an export file to disk from the browser isn't wired up in the
/// PWA build yet, so this fails cleanly with a message the Settings screen
/// surfaces in a snackbar rather than crashing. (The data itself never left the
/// device — nothing was gathered off it.)
Future<void> shareExport({
  required String content,
  required String fileName,
  required String subject,
  required String text,
}) async {
  throw UnsupportedError(
    'Saving an export file isn\'t available in the web version of Reckon yet '
    '— use the Android app to export.',
  );
}
