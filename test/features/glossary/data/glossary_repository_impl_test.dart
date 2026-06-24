import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/glossary/data/glossary_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlossaryRepositoryImpl', () {
    test('loads all 8 entries from bundled asset', () async {
      final repo = GlossaryRepositoryImpl();
      final entries = await repo.all();
      expect(entries, hasLength(8));
      expect(entries.map((e) => e.id), containsAll([
        'inner-crowd',
        'reference-class',
        'pre-mortem',
        'dialectical-bootstrapping',
        'calibration',
        'reveal-effect',
        'criteria-vs-reasoning',
        'resulting',
      ]));
    });

    test('byId returns the right entry', () async {
      final repo = GlossaryRepositoryImpl();
      final entry = await repo.byId('reference-class');
      expect(entry, isNotNull);
      expect(entry!.title, 'Reference Class');
    });

    test('byId returns null for unknown id', () async {
      final repo = GlossaryRepositoryImpl();
      expect(await repo.byId('does-not-exist'), isNull);
    });

    test('entries have non-empty content', () async {
      final repo = GlossaryRepositoryImpl();
      for (final e in await repo.all()) {
        expect(e.title, isNotEmpty, reason: e.id);
        expect(e.oneLine, isNotEmpty, reason: e.id);
        expect(e.paragraph, isNotEmpty, reason: e.id);
        expect(e.example, isNotEmpty, reason: e.id);
      }
    });

    test('every entry has at least one curated citation', () async {
      final repo = GlossaryRepositoryImpl();
      for (final e in await repo.all()) {
        expect(e.sources, isNotEmpty, reason: e.id);
        for (final s in e.sources) {
          expect(s.authors, isNotEmpty);
          expect(s.title, isNotEmpty);
          expect(s.year, greaterThan(1900));
        }
      }
    });
  });
}
