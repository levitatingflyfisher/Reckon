import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The household phrase that pairs this device with the family's stove (the
/// home server speaking domovoi's encrypted stove protocol). The phrase IS
/// the pairing: the same phrase on both ends derives the same frame key, and
/// nothing else can open or forge a frame. It lives in secure storage on
/// this device and never crosses the wire — only frames sealed with the key
/// derived from it do.
///
/// Follows [AnthropicKeyStore]; storage is injectable so tests run without
/// platform channels.
class StoveSecretStore {
  const StoveSecretStore({FlutterSecureStorage storage = _defaultStorage})
      : _storage = storage;

  static const _defaultStorage = FlutterSecureStorage();
  static const _keyName = 'reckon.stove_household_phrase';

  final FlutterSecureStorage _storage;

  Future<String?> getPhrase() => _storage.read(key: _keyName);

  Future<void> setPhrase(String phrase) =>
      _storage.write(key: _keyName, value: phrase);

  Future<void> clearPhrase() => _storage.delete(key: _keyName);

  Future<bool> hasPhrase() async {
    final phrase = await getPhrase();
    return phrase != null && phrase.isNotEmpty;
  }
}

final stoveSecretStoreProvider =
    Provider<StoveSecretStore>((ref) => const StoveSecretStore());

/// Whether a household phrase is stored. Invalidate after set/clear — the
/// duel button's runnability check watches this.
final hasStovePhraseProvider = FutureProvider<bool>((ref) {
  return ref.watch(stoveSecretStoreProvider).hasPhrase();
});
