import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/party/data/local_party_repository.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/domain/entities/party_result.dart';
import 'package:reckon/features/party/sync/party_codec.dart';
import 'package:reckon/features/party/sync/party_crypto.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';
import 'package:reckon/features/party/sync/party_link.dart';
import 'package:reckon/features/party/sync/party_sync_service.dart';
import 'package:reckon/features/party/sync/transport/channel_relay.dart';
import 'package:reckon/features/party/sync/transport/duplex_channel.dart';

/// End-to-end: the full encrypted sync stack (PartySyncService → crypto → codec)
/// running over a peer-to-peer DuplexChannel — i.e. the exact path Nearby and
/// WebRTC will use, proven with an in-memory channel and no server.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const options = [
    PartyOption(id: 'a', label: 'Beach'),
    PartyOption(id: 'b', label: 'Mountains'),
  ];

  test('a guest joins and votes over a peer channel; host tallies it',
      () async {
    // --- Host device: owns the party, runs the channel relay host. ---
    final hostDb = AppDatabase(NativeDatabase.memory());
    final hostRepo = LocalPartyRepository(hostDb);
    final party = await hostRepo.createParty(
        title: 'Trip?', options: options, votingMethod: VotingMethod.approval);

    final gen = await PartyCrypto.generate();
    final pair = inMemoryChannelPair();
    final host = ChannelRelayHost(pair.a);
    // Host publishes its own encrypted party blob into its responder.
    host.seed(party.id,
        await gen.crypto.encryptJson(PartyCodec.partyToJson(party)));

    // --- Guest device: only has the join link; talks over the channel. ---
    final guestDb = AppDatabase(NativeDatabase.memory());
    final guestRepo = LocalPartyRepository(guestDb);
    final guest = PartySyncService(
      local: guestRepo,
      keys: InMemoryPartyKeyStore(),
      relayFor: (_) async => ChannelPartyRelay(pair.b),
    );

    final link = PartyJoinLink(
      relayBaseUrl: 'p2p://peer',
      partyId: party.id,
      keyString: gen.keyString,
    ).toUrl();

    final joined = await guest.joinParty(link);
    expect(joined.id, party.id);
    expect(joined.title, 'Trip?');
    expect((await guestRepo.getParty(party.id))!.options, options);

    // Guest votes locally and pushes the (encrypted) ballot over the channel.
    final ballot = Ballot.approval(
        id: 'g1', party: joined, approvedOptionIds: const ['b']);
    await guestRepo.submitBallot(party.id, ballot);
    await guest.pushBallot(party.id, ballot);

    // Host pulls the ballot back over the channel and tallies it.
    final hostSync = PartySyncService(
      local: hostRepo,
      keys: _seededKeys(party.id, gen.keyString),
      relayFor: (_) async => ChannelPartyRelay(pair.b),
    );
    await hostSync.pull(party.id);
    final result = await hostRepo.computeResult(party.id) as ApprovalResult;
    expect(result.ballotCount, 1);
    expect(result.tallies.firstWhere((t) => t.optionId == 'b').approvals, 1);

    await hostDb.close();
    await guestDb.close();
  });
}

PartyKeyStore _seededKeys(String partyId, String key) {
  final store = InMemoryPartyKeyStore();
  store.put(partyId, PartySyncInfo(baseUrl: 'p2p://peer', keyString: key));
  return store;
}
