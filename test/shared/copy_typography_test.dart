import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// House style for words on screen: no spaced em dashes, and typographic
/// apostrophes and quotes (’ “ ”) rather than typewriter ones (' ").
/// A source scan over string literals in lib/ (the Sundial / Furrow /
/// Peckish scan; the fleet has no shared home for it yet), plus the text of
/// the Learn entries and the reference classes, which are shown on screen.
/// Comments, imports and log lines are ignored.
///
/// Exempt, because their text is not on-screen copy: what is sent to a
/// language model (prompts, personas, sentinels) and parsed back from it,
/// wire formats (the outside-bots codec), and the export file formats.
const _exempt = [
  'llm_prompts.dart',
  'private_mode_impl.dart',
  'anthropic_llm_service.dart',
  'anthropic_client.dart',
  'openai_compat_llm_service.dart',
  'openai_compat_client.dart',
  'stove_llm_service_io.dart',
  'connected_mode_impl.dart',
  'forecaster_repository_impl.dart',
  'bounty_codec.dart',
  'formatters.dart',
];

void main() {
  final literal = RegExp(r'"([^"\\]|\\.)*"' "|" r"'([^'\\]|\\.)*'");

  Iterable<(String, int, String)> literals() sync* {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => !_exempt.any(f.path.endsWith));
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final t = line.trimLeft();
        if (t.startsWith('//') || line.contains('debugPrint(')) continue;
        if (t.startsWith('import ') || t.startsWith('export ')) continue;
        if (t.startsWith('part ')) continue;
        for (final m in literal.allMatches(line)) {
          yield (f.path, i + 1, m.group(0)!);
        }
      }
    }
  }

  /// Every string value in a JSON asset, with where it came from.
  Iterable<(String, String)> assetStrings(String path) sync* {
    Iterable<String> walk(Object? v) sync* {
      if (v is String) yield v;
      if (v is List) {
        for (final e in v) {
          yield* walk(e);
        }
      }
      if (v is Map) {
        for (final e in v.values) {
          yield* walk(e);
        }
      }
    }

    for (final s in walk(jsonDecode(File(path).readAsStringSync()))) {
      yield (path, s);
    }
  }

  final assets = [
    ...assetStrings('assets/glossary.json'),
    ...assetStrings('assets/reference_classes.json'),
  ];

  test('no spaced em dash in on-screen copy', () {
    final hits = [
      for (final (path, line, lit) in literals())
        if (lit.contains(' — ') || lit.endsWith(" —'") || lit.endsWith(' —"'))
          '$path:$line $lit',
      for (final (path, s) in assets)
        if (s.contains(' — ')) '$path: $s',
    ];
    expect(hits, isEmpty);
  });

  test('no typewriter apostrophe or quote inside on-screen copy', () {
    final apostrophe = RegExp(r"[A-Za-z]'[A-Za-z]");
    final escaped = RegExp(r"[A-Za-z}]\\'[A-Za-z]");
    final hits = [
      for (final (path, line, lit) in literals())
        if ((lit.startsWith('"') &&
                apostrophe.hasMatch(lit.substring(1, lit.length - 1))) ||
            (lit.startsWith("'") &&
                (lit.substring(1, lit.length - 1).contains('"') ||
                    escaped.hasMatch(lit))))
          '$path:$line $lit',
      for (final (path, s) in assets)
        if (apostrophe.hasMatch(s) || s.contains('"')) '$path: $s',
    ];
    expect(hits, isEmpty);
  });
}
