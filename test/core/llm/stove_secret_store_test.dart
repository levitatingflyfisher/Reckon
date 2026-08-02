import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/stove_secret_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('starts empty', () async {
    const store = StoveSecretStore();
    expect(await store.getPhrase(), isNull);
    expect(await store.hasPhrase(), isFalse);
  });

  test('set / get / has / clear round-trip', () async {
    const store = StoveSecretStore();
    await store.setPhrase('legal winner thank year wave sausage worth useful '
        'legal winner thank yellow');
    expect(await store.getPhrase(), startsWith('legal winner'));
    expect(await store.hasPhrase(), isTrue);

    await store.clearPhrase();
    expect(await store.getPhrase(), isNull);
    expect(await store.hasPhrase(), isFalse);
  });

  test('uses the reckon.stove_household_phrase namespace', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'reckon.stove_household_phrase': 'zoo zoo zoo'});
    const store = StoveSecretStore();
    expect(await store.getPhrase(), 'zoo zoo zoo');
  });

  test('an empty stored value does not count as a phrase', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'reckon.stove_household_phrase': ''});
    const store = StoveSecretStore();
    expect(await store.hasPhrase(), isFalse);
  });
}
