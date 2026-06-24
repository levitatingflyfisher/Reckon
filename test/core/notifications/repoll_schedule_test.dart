import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/notifications/repoll_schedule.dart';

void main() {
  group('computeRepollSchedule', () {
    final now = DateTime(2026, 4, 10);

    test('no deadline returns empty schedule', () {
      final dates = computeRepollSchedule(now: now, deadline: null);
      expect(dates, isEmpty);
    });

    test('deadline in the past returns empty schedule', () {
      final dates = computeRepollSchedule(
        now: now,
        deadline: now.subtract(const Duration(days: 1)),
      );
      expect(dates, isEmpty);
    });

    test('deadline > 14 days uses 5-7 day cadence', () {
      final deadline = now.add(const Duration(days: 30));
      final dates = computeRepollSchedule(
        now: now,
        deadline: deadline,
        random: Random(42),
      );
      expect(dates, isNotEmpty);
      expect(dates.last.isBefore(deadline), true);
      final firstGap = dates.first.difference(now).inDays;
      expect(firstGap, inInclusiveRange(5, 7));
    });

    test('deadline 7-14 days uses 3-day cadence initially', () {
      final deadline = now.add(const Duration(days: 10));
      final dates = computeRepollSchedule(now: now, deadline: deadline);
      expect(dates, isNotEmpty);
      final firstGap = dates.first.difference(now).inDays;
      expect(firstGap, 3);
    });

    test('deadline 3-7 days uses 2-day cadence initially', () {
      final deadline = now.add(const Duration(days: 5));
      final dates = computeRepollSchedule(now: now, deadline: deadline);
      expect(dates, isNotEmpty);
      final firstGap = dates.first.difference(now).inDays;
      expect(firstGap, 2);
    });

    test('deadline < 3 days uses daily cadence', () {
      final deadline = now.add(const Duration(days: 2));
      final dates = computeRepollSchedule(now: now, deadline: deadline);
      expect(dates, isNotEmpty);
      if (dates.length > 1) {
        final gap = dates[1].difference(dates[0]).inDays;
        expect(gap, 1);
      }
    });

    test('never schedules past the deadline', () {
      final deadline = now.add(const Duration(days: 30));
      final dates = computeRepollSchedule(
        now: now,
        deadline: deadline,
        random: Random(42),
      );
      for (final d in dates) {
        expect(d.isBefore(deadline) || d.isAtSameMomentAs(deadline), true);
      }
    });
  });
}
