import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The user's own Anthropic API key, held in secure storage on this device
/// and sent nowhere but api.anthropic.com (ADR-0002: no key in the binary,
/// no silent cloud default — cloud runs only on a key the user typed in).
///
/// Follows the HF-token pattern in [ModelDownloadService]; storage is
/// injectable so tests run without platform channels.
class AnthropicKeyStore {
  const AnthropicKeyStore({FlutterSecureStorage storage = _defaultStorage})
      : _storage = storage;

  static const _defaultStorage = FlutterSecureStorage();
  static const _keyName = 'reckon.anthropic_api_key';

  final FlutterSecureStorage _storage;

  Future<String?> getKey() => _storage.read(key: _keyName);

  Future<void> setKey(String key) => _storage.write(key: _keyName, value: key);

  Future<void> clearKey() => _storage.delete(key: _keyName);

  Future<bool> hasKey() async {
    final key = await getKey();
    return key != null && key.isNotEmpty;
  }
}

final anthropicKeyStoreProvider =
    Provider<AnthropicKeyStore>((ref) => const AnthropicKeyStore());

/// Whether a BYOK key is stored. Invalidate after set/clear — the duel
/// button's runnability check watches this.
final hasAnthropicKeyProvider = FutureProvider<bool>((ref) {
  return ref.watch(anthropicKeyStoreProvider).hasKey();
});
