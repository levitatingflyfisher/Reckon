import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/party_crypto.dart';

void main() {
  test('encrypt → decrypt round-trips a JSON object', () async {
    final gen = await PartyCrypto.generate();
    const data = {'title': 'Dinner', 'options': ['tacos', 'sushi']};

    final blob = await gen.crypto.encryptJson(data);
    final back = await gen.crypto.decryptJson(blob);

    expect(back['title'], 'Dinner');
    expect(back['options'], ['tacos', 'sushi']);
  });

  test('ciphertext does not leak plaintext', () async {
    final gen = await PartyCrypto.generate();
    final blob = await gen.crypto.encryptJson({'secret': 'tacos-vs-sushi'});
    expect(String.fromCharCodes(blob).contains('tacos'), isFalse);
  });

  test('a different key cannot decrypt (authentication fails)', () async {
    final a = await PartyCrypto.generate();
    final b = await PartyCrypto.generate();
    final blob = await a.crypto.encryptJson({'x': 1});

    expect(b.crypto.decryptJson(blob), throwsA(anything));
  });

  test('key string round-trips through fromKeyString', () async {
    final gen = await PartyCrypto.generate();
    final blob = await gen.crypto.encryptJson({'x': 42});

    final restored = PartyCrypto.fromKeyString(gen.keyString);
    expect((await restored.decryptJson(blob))['x'], 42);
  });
}
