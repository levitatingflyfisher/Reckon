import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fleet jargon ruling: made-up coinages become plain words wherever a
/// person reads them. Reckon's were case (a decision), duel (asking the
/// forecasters), bounty (outside bots), party / ReckonParty (a group vote),
/// re-poll (weighing in again) and Ghost (no account). Identifiers, routes,
/// payloads and wire formats keep their names; only string literals on the
/// screens, in notifications and in the insight sentences are held here.
void main() {
  final retired = RegExp(
    r'\b(cases?|duels?|bount(y|ies)|part(y|ies)|re-?poll(s|ed|ing)?|'
    r'ReckonParty|Ghost)\b',
    caseSensitive: false,
  );
  // A literal that is only a route, payload, id or key, e.g. '/case/$id'.
  final machine = RegExp(r"""^['"][\w/:$.{}\-?=]*['"]$""");
  final literal = RegExp(r"'(?:[^'\\\n]|\\.)*'" '|' r'"(?:[^"\\\n]|\\.)*"');

  List<String> offenders(Iterable<File> files) {
    final found = <String>[];
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//') || line.startsWith('import ')) continue;
        if (line.contains('debugPrint(') || line.contains('Key(')) continue;
        for (final m in literal.allMatches(lines[i])) {
          final s = m.group(0)!;
          if (machine.hasMatch(s)) continue;
          // Interpolated code (`${party.title}`, `$caseId`) is not words.
          final words = s
              .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
              .replaceAll(RegExp(r'\$\w+'), '');
          if (!retired.hasMatch(words)) continue;
          found.add('${f.path}:${i + 1}: $s');
        }
      }
    }
    return found;
  }

  test('screens, notifications and insights use the plain words', () {
    final files = <File>[
      for (final e in Directory('lib/features').listSync(recursive: true))
        if (e is File &&
            e.path.endsWith('.dart') &&
            e.path.contains('/presentation/'))
          e,
      File('lib/core/notifications/local_notification_service_io.dart'),
      File('lib/features/record/domain/usecases/compute_insight_cards.dart'),
      File('lib/app/root_overrides.dart'),
    ];
    expect(offenders(files), isEmpty);
  });

  test('Learn entries use the plain words', () {
    // "Generate the case against it" is ordinary English (an argument), so
    // only the coinages that name Reckon's own objects are held here.
    final text = File('assets/glossary.json').readAsStringSync();
    final coined = RegExp(r'\b(re-?poll\w*|duels?|bount(y|ies)|closed \d+ cases)\b',
        caseSensitive: false);
    expect(coined.allMatches(text).map((m) => m.group(0)).toList(), isEmpty);
  });
}
