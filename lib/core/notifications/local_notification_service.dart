import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_id.dart';

/// Maps a notification [payload] to the in-app route it should deep-link to.
/// Payloads are `repoll:<caseId>` and `resolution:<caseId>`. Returns null for
/// anything unrecognised (e.g. legacy payloads with no case id).
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

class LocalNotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  final _selections = StreamController<String>.broadcast();

  /// Emits the payload of a notification the user tapped while the app was
  /// running. Listen from the app root to deep-link via [routeForNotificationPayload].
  Stream<String> get selections => _selections.stream;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _selections.add(payload);
      },
    );
    _initialized = true;
  }

  /// If the app was cold-started by tapping a notification, returns that
  /// notification's payload (for the router's initial deep-link); else null.
  Future<String?> initialLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  Future<bool> requestPermissions() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Convert a wall-clock local [DateTime] into an absolute UTC-anchored
  /// [tz.TZDateTime]. We route through UTC deliberately so we don't depend
  /// on `tz.setLocalLocation` (which requires an IANA zone name from a
  /// platform call) — the absolute instant is what the notification system
  /// actually schedules against, and the OS renders it in the user's
  /// current local time.
  tz.TZDateTime _absolute(DateTime when) =>
      tz.TZDateTime.from(when.toUtc(), tz.UTC);

  Future<void> scheduleRepoll({
    required int id,
    required String caseId,
    required String caseTitle,
    required DateTime when,
  }) async {
    await _plugin.zonedSchedule(
      id,
      caseTitle,
      'Time to check in',
      _absolute(when),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reckon_repoll',
          'Re-poll reminders',
          channelDescription: 'Gentle check-ins on your open cases',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      // Inexact mode doesn't require the "Alarms & reminders" special
      // permission on Android 12+/14+ and never throws SecurityException.
      // Reminders may drift by ~15 min; acceptable for a decision journal.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'repoll:$caseId',
    );
  }

  Future<void> scheduleResolutionCheckIn({
    required int id,
    required String caseId,
    required String caseTitle,
    required String chosenOption,
    required DateTime when,
  }) async {
    await _plugin.zonedSchedule(
      id,
      caseTitle,
      'You decided $chosenOption. How do you feel about it?',
      _absolute(when),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reckon_resolution',
          'Resolution check-ins',
          channelDescription: 'One follow-up after you decide',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'resolution:$caseId',
    );
  }

  /// Cancel every notification scheduled for [caseId]. Uses the same
  /// [notificationIdFor] id-space the schedulers use, plus the dedicated
  /// resolution-checkin slot, so cancels line up with what was scheduled.
  /// [repollSlotCount] must match the number of repoll slots that were
  /// originally scheduled for this case.
  Future<void> cancelCaseNotifications(
    String caseId, {
    required int repollSlotCount,
  }) async {
    for (var i = 0; i < repollSlotCount; i++) {
      await _plugin.cancel(notificationIdFor(caseId, i));
    }
    await _plugin.cancel(notificationIdFor(caseId, resolutionSlot));
  }
}
