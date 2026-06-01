import '../entities/clarity_score.dart';

class ComputeClarityScore {
  const ComputeClarityScore();

  ClarityScore call(List<int> satisfactionScores) {
    if (satisfactionScores.isEmpty) {
      return const ClarityScore(value: 0, caseCount: 0);
    }
    final avg = satisfactionScores.reduce((a, b) => a + b) /
        satisfactionScores.length;
    final value = ((avg + 2) / 4 * 100).round().clamp(0, 100);
    return ClarityScore(value: value, caseCount: satisfactionScores.length);
  }
}
