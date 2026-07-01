// Platform-selected notification backend. The native variant drives
// `flutter_local_notifications`; the web variant is an inert no-op. The plugin
// transitively imports `dart:io`/`dart:ffi` (via its Linux backend), so the web
// build must never reach it — `dart.library.io` selects the right file, both
// of which expose the same `LocalNotificationService` surface.
export 'local_notification_service_web.dart'
    if (dart.library.io) 'local_notification_service_io.dart';

/// Maps a notification [payload] to the in-app route it should deep-link to.
/// Payloads are `repoll:<caseId>` and `resolution:<caseId>`. Returns null for
/// anything unrecognised (e.g. legacy payloads with no case id).
///
/// Pure string parsing with no platform dependency, so it lives in the facade
/// and is shared by both platform variants.
String? routeForNotificationPayload(String payload) {
  final sep = payload.indexOf(':');
  if (sep <= 0 || sep == payload.length - 1) return null;
  final kind = payload.substring(0, sep);
  final caseId = payload.substring(sep + 1);
  switch (kind) {
    case 'repoll':
      return '/repoll/$caseId';
    case 'resolution':
      return '/resolution-checkin/$caseId';
    default:
      return null;
  }
}
