import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/core/database/database_providers.dart';
import 'package:reckon/features/party/data/local_party_repository.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/sync/party_codec.dart';
import 'package:reckon/features/party/sync/party_crypto.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';
import 'package:reckon/features/party/sync/party_link.dart';
import 'package:reckon/features/party/sync/party_sync_providers.dart';
import 'package:reckon/features/party/sync/transport/channel_relay.dart';
import 'package:reckon/features/party/sync/transport/duplex_channel.dart';

/// Verifies the Riverpod sync wiring: a party joined through
/// [partySyncServiceProvider] lands in the database the providers resolve to.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('joinParty through the provider graph imports into the local db',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Host owns an encrypted party served over an in-memory channel.
    final gen = await PartyCrypto.generate();
    final source = LocalPartyRepository(AppDatabase(NativeDatabase.memory()));
    final party = await source.createParty(
      title: 'Lunch?',
      options: const [
        PartyOption(id: 'a', label: 'Ramen'),
        PartyOption(id: 'b', label: 'Pho'),
      ],
      votingMethod: VotingMethod.approval,
    );
    final pair = inMemoryChannelPair();
    ChannelRelayHost(pair.a).seed(
      party.id,
      await gen.crypto.encryptJson(PartyCodec.partyToJson(party)),
    );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      partyKeyStoreProvider.overrideWithValue(InMemoryPartyKeyStore()),
      partyRelayResolverProvider
          .overrideWithValue((_) async => ChannelPartyRelay(pair.b)),
    ]);
    addTearDown(container.dispose);

    final sync = container.read(partySyncServiceProvider);
    final link = PartyJoinLink(
      relayBaseUrl: 'p2p://peer',
      partyId: party.id,
      keyString: gen.keyString,
    ).toUrl();

    final joined = await sync.joinParty(link);
    expect(joined.title, 'Lunch?');

    // It landed in the db the providers resolve to, and reads back as synced.
    final stored = await LocalPartyRepository(db).getParty(party.id);
    expect(stored, isNotNull);
    expect(await container.read(partyIsSyncedProvider(party.id).future), isTrue);
  });
}
