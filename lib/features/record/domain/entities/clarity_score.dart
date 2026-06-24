class ClarityScore {
  const ClarityScore({required this.value, required this.caseCount});

  final int value;
  final int caseCount;

  bool get hasEnoughData => caseCount >= 5;
}
