import 'dart:async';

/// Web build: browsers have no OS notification channel we schedule against, so
/// every operation is an inert no-op and [selections] never emits. Web users
/// see their open cases in-app rather than via a scheduled reminder. This
/// variant deliberately imports nothing from `flutter_local_notifications`,
/// which pulls `dart:io`/`dart:ffi` in through its Linux backend and would
/// break `flutter build web`.
class LocalNotificationService {
  LocalNotificationService();

  final _selections = StreamController<String>.broadcast();

  Stream<String> get selections => _selections.stream;

  Future<void> init() async {}

  Future<String?> initialLaunchPayload() async => null;

  Future<bool> requestPermissions() async => false;

  Future<void> scheduleRepoll({
    required int id,
    required String caseId,
    required DateTime when,
  }) async {}

  Future<void> scheduleResolutionCheckIn({
    required int id,
    required String caseId,
    required DateTime when,
  }) async {}

  Future<void> cancelCaseNotifications(
    String caseId, {
    required int repollSlotCount,
  }) async {}
}
