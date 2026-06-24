import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';

void main() {
  group('Citation', () {
    test('fromJson reads author, title, url', () {
      final c = Citation.fromJson({
        'author': 'W. Bradford Wilcox',
        'title': 'Get Married',
        'url': 'https://ifstudies.org',
      });
      expect(c.author, 'W. Bradford Wilcox');
      expect(c.title, 'Get Married');
      expect(c.url, 'https://ifstudies.org');
    });

    test('fromJson defaults missing keys to empty strings', () {
      final c = Citation.fromJson({'title': 'Untitled study'});
      expect(c.author, '');
      expect(c.title, 'Untitled study');
      expect(c.url, '');
    });

    test('fromJson tolerates non-string values', () {
      final c = Citation.fromJson({'author': 42, 'title': null, 'url': true});
      expect(c.author, '');
      expect(c.title, '');
      expect(c.url, '');
    });

    test('toJson round-trips through fromJson', () {
      const original = Citation(
        author: 'CDC NSFG',
        title: 'First Marriages in the US',
        url: 'https://www.cdc.gov/nchs/nsfg/',
      );
      final restored = Citation.fromJson(original.toJson());
      expect(restored.author, original.author);
      expect(restored.title, original.title);
      expect(restored.url, original.url);
    });

    test('hasLink is true only when url is non-empty', () {
      expect(
        const Citation(author: 'a', title: 't', url: 'https://x').hasLink,
        isTrue,
      );
      expect(const Citation(author: 'a', title: 't', url: '').hasLink, isFalse);
    });
  });
}
