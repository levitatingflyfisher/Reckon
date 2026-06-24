/// A single curated literature citation backing a reference class.
///
/// Citations originate only from the human-curated `sources` of a
/// [ReferenceClassEntry] — never from the LLM. They are snapshotted onto an
/// [OutsideView] at generation time so the record and exports stay honest.
class Citation {
  const Citation({
    required this.author,
    required this.title,
    required this.url,
  });

  final String author;
  final String title;
  final String url;

  /// Whether this citation has a followable link.
  bool get hasLink => url.isNotEmpty;

  /// Reads a source map from the reference-class JSON. Any missing or
  /// non-string field defaults to an empty string so malformed seed data can
  /// never crash the Outside View.
  factory Citation.fromJson(Map<String, dynamic> json) {
    String str(Object? value) => value is String ? value : '';
    return Citation(
      author: str(json['author']),
      title: str(json['title']),
      url: str(json['url']),
    );
  }

  Map<String, dynamic> toJson() => {
        'author': author,
        'title': title,
        'url': url,
      };

  /// Decodes a stored/seed JSON list (or null) into citations. NULL — e.g. an
  /// `outside_views.citations` column written before citations shipped —
  /// becomes an empty list. Single source of truth for citation decoding.
  static List<Citation> listFromDynamic(List<dynamic>? raw) => raw == null
      ? const []
      : raw.map((e) => Citation.fromJson(e as Map<String, dynamic>)).toList();
}
