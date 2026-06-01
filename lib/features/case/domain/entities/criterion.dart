class Criterion {
  const Criterion({required this.label, required this.weight});
  final String label;
  final double weight;

  Map<String, dynamic> toJson() => {'label': label, 'weight': weight};

  factory Criterion.fromJson(Map<String, dynamic> json) => Criterion(
        label: json['label'] as String,
        weight: (json['weight'] as num).toDouble(),
      );
}
