import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/notifications/local_notification_service.dart';

void main() {
  group('routeForNotificationPayload', () {
    test('repoll payload deep-links to the re-poll screen', () {
      expect(routeForNotificationPayload('repoll:abc-123'), '/repoll/abc-123');
    });

    test('resolution payload deep-links to the check-in screen', () {
      expect(routeForNotificationPayload('resolution:abc-123'),
          '/resolution-checkin/abc-123');
    });

    test('case id containing nothing weird is preserved verbatim', () {
      const id = '550e8400-e29b-41d4-a716-446655440000';
      expect(routeForNotificationPayload('repoll:$id'), '/repoll/$id');
    });

    test('legacy payloads with no case id return null (no bad nav)', () {
      expect(routeForNotificationPayload('repoll'), isNull);
      expect(routeForNotificationPayload('resolution'), isNull);
    });

    test('unknown kind returns null', () {
      expect(routeForNotificationPayload('something:abc'), isNull);
    });

    test('empty / malformed payloads return null', () {
      expect(routeForNotificationPayload(''), isNull);
      expect(routeForNotificationPayload(':abc'), isNull);
      expect(routeForNotificationPayload('repoll:'), isNull);
    });
  });
}
