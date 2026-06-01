enum Confidence { low, medium, high }

class Poll {
  const Poll({
    required this.id,
    required this.caseId,
    required this.createdAt,
    required this.pollNumber,
    required this.lean,
    required this.confidence,
    this.rationale,
    this.revealed = false,
  });

  final String id;
  final String caseId;
  final DateTime createdAt;
  final int pollNumber;
  final int lean;
  final Confidence confidence;
  final String? rationale;
  final bool revealed;
}
