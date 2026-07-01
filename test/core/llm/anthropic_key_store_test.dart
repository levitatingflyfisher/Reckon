import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/anthropic_key_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('starts empty', () async {
    const store = AnthropicKeyStore();
    expect(await store.getKey(), isNull);
    expect(await store.hasKey(), isFalse);
  });

  test('set / get / has / clear round-trip', () async {
    const store = AnthropicKeyStore();
    await store.setKey('sk-ant-user-123');
    expect(await store.getKey(), 'sk-ant-user-123');
    expect(await store.hasKey(), isTrue);

    await store.clearKey();
    expect(await store.getKey(), isNull);
    expect(await store.hasKey(), isFalse);
  });

  test('uses the reckon.anthropic_api_key namespace', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'reckon.anthropic_api_key': 'sk-ant-preexisting'});
    const store = AnthropicKeyStore();
    expect(await store.getKey(), 'sk-ant-preexisting');
  });

  test('an empty stored value does not count as a key', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'reckon.anthropic_api_key': ''});
    const store = AnthropicKeyStore();
    expect(await store.hasKey(), isFalse);
  });
}
