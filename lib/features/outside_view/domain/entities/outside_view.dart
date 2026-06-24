import 'citation.dart';

class OutsideView {
  const OutsideView({
    required this.id,
    required this.caseId,
    required this.generatedAt,
    required this.baseRateSummary,
    required this.referenceClassUsed,
    required this.uncertaintyLevel,
    required this.stratificationFactors,
    required this.llmMode,
    required this.modelVersion,
    this.citations = const [],
  });

  final String id;
  final String caseId;
  final DateTime generatedAt;
  final String baseRateSummary;
  final String referenceClassUsed;
  final String uncertaintyLevel;
  final Map<String, dynamic> stratificationFactors;
  final String llmMode;
  final String modelVersion;

  /// Curated literature citations from the reference class that informed this
  /// view. Sourced from human-curated data, never the LLM. Empty for views
  /// generated before citations shipped (NULL column on upgraded installs).
  final List<Citation> citations;
}
