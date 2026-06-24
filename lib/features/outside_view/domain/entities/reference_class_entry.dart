class ReferenceClassEntry {
  const ReferenceClassEntry({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.baseRateDescription,
    required this.stratificationVariables,
    required this.sources,
    required this.commonCriteria,
    required this.commonRegretPatterns,
    required this.uncertaintyLevel,
    required this.lastUpdated,
  });

  final String id;
  final String category;
  final String subcategory;
  final String baseRateDescription;
  final List<String> stratificationVariables;
  final List<Map<String, dynamic>> sources;
  final List<String> commonCriteria;
  final String commonRegretPatterns;
  final String uncertaintyLevel;
  final String lastUpdated;
}
