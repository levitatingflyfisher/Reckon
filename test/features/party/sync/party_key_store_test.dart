import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';

/// Group entries give a persistent circle a long-lived home in the key store
/// (`reckon.group_key.<groupId>`), alongside — and strictly separate from —
/// the per-decision party keys (`reckon.party_key.<partyId>`). Same id in the
/// two namespaces must never collide.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const info = PartySyncInfo(baseUrl: 'https://r.example', keyString: 'kAAA');
  const other = PartySyncInfo(baseUrl: 'lan://10.0.0.2:4242', keyString: 'kBBB');

  group('InMemoryPartyKeyStore', () {
    test('group entries round-trip and stay apart from party keys', () async {
      final store = InMemoryPartyKeyStore();
      await store.put('x1', info);
      await store.putGroup('x1', other); // same id, different namespace

      final party = await store.get('x1');
      final grp = await store.getGroup('x1');
      expect(party!.keyString, 'kAAA');
      expect(grp!.keyString, 'kBBB');
      expect(grp.baseUrl, 'lan://10.0.0.2:4242');
    });

    test('getGroup returns null for an unknown group', () async {
      expect(await InMemoryPartyKeyStore().getGroup('nope'), isNull);
    });
  });

  group('SecurePartyKeyStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('group entries persist under reckon.group_key.<id>', () async {
      final store = SecurePartyKeyStore();
      await store.putGroup('g1', info);

      final loaded = await store.getGroup('g1');
      expect(loaded!.baseUrl, 'https://r.example');
      expect(loaded.keyString, 'kAAA');

      // The namespaces must not bleed into each other.
      expect(await store.get('g1'), isNull);
    });

    test('party keys keep their original namespace', () async {
      final store = SecurePartyKeyStore();
      await store.put('p1', info);
      expect((await store.get('p1'))!.keyString, 'kAAA');
      expect(await store.getGroup('p1'), isNull);
    });
  });
}
