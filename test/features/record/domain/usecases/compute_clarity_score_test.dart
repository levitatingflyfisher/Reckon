import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/record/domain/usecases/compute_clarity_score.dart';

void main() {
  const uc = ComputeClarityScore();

  test('empty input returns 0 with zero case count', () {
    final score = uc.call([]);
    expect(score.value, 0);
    expect(score.caseCount, 0);
  });

  test('all +2 returns 100', () {
    final score = uc.call([2, 2, 2]);
    expect(score.value, 100);
  });

  test('all -2 returns 0', () {
    final score = uc.call([-2, -2]);
    expect(score.value, 0);
  });

  test('mixed around zero returns ~50', () {
    final score = uc.call([-1, 0, 1]);
    expect(score.value, 50);
  });

  test('hasEnoughData threshold is 5', () {
    expect(uc.call([1, 1, 1, 1]).hasEnoughData, false);
    expect(uc.call([1, 1, 1, 1, 1]).hasEnoughData, true);
  });
}
