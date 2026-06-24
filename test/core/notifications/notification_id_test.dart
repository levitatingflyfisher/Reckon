import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/notifications/notification_id.dart';

void main() {
  group('notificationIdFor', () {
    test('produces a non-negative 32-bit int', () {
      for (final id in [
        '00000000-0000-0000-0000-000000000000',
        'f' * 32,
        'c1',
        'case-with-a-fairly-long-slug-that-may-hash-big',
      ]) {
        final n = notificationIdFor(id, 0);
        expect(n, greaterThanOrEqualTo(0));
        expect(n, lessThan(1 << 31));
      }
    });

    test('is stable across calls for the same inputs', () {
      final a = notificationIdFor('case-xyz', 3);
      final b = notificationIdFor('case-xyz', 3);
      expect(a, b);
    });

    test('differs between slots for the same case', () {
      final a = notificationIdFor('case-xyz', 0);
      final b = notificationIdFor('case-xyz', 1);
      expect(a, isNot(b));
    });

    test('slot offset never overflows into the sign bit', () {
      // mask is 0x3FFFFFFF (30 bits), so slot up to 0x3FFFFFFF leaves headroom.
      final n = notificationIdFor('any-case', 100);
      expect(n, lessThan(1 << 31));
    });
  });
}
