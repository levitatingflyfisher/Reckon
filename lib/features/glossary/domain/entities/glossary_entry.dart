class GlossaryEntry {
  const GlossaryEntry({
    required this.id,
    required this.title,
    required this.oneLine,
    required this.paragraph,
    required this.example,
    this.sources = const [],
  });

  final String id;
  final String title;
  final String oneLine;
  final String paragraph;
  final String example;
  final List<Citation> sources;

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) => GlossaryEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        oneLine: json['oneLine'] as String,
        paragraph: json['paragraph'] as String,
        example: json['example'] as String,
        sources: (json['sources'] as List? ?? const [])
            .map((raw) => Citation.fromJson(raw as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class Citation {
  const Citation({
    required this.authors,
    required this.year,
    required this.title,
    this.venue,
    this.url,
  });

  final String authors;
  final int year;
  final String title;
  final String? venue;
  final String? url;

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
        authors: json['authors'] as String,
        year: json['year'] as int,
        title: json['title'] as String,
        venue: json['venue'] as String?,
        url: json['url'] as String?,
      );
}
