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
import 'package:reckon/features/party/sync/transport/channel_relay.dart';
import 'package:reckon/features/party/sync/transport/lan_host_controller.dart';
import 'package:reckon/features/party/sync/transport/lan_socket_channel.dart';

/// The host controller, end-to-end over real loopback TCP: it hosts a party,
/// a remote peer votes over the socket, and `syncToLocal` folds that vote into
/// the host's own tally.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('hosts a party, then merges a peer vote into the local tally', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalPartyRepository(db);
    final keys = InMemoryPartyKeyStore();

    final party = await repo.createParty(
      title: 'Where to?',
      options: const [
        PartyOption(id: 'a', label: 'Park'),
        PartyOption(id: 'b', label: 'Pub'),
      ],
      votingMethod: VotingMethod.approval,
    );
    // The host has already cast its own vote locally.
    await repo.submitBallot(
        party.id,
        Ballot.approval(
            id: 'host', party: party, approvedOptionIds: const ['a']));

    final controller = LanHostController(repo, keys);
    addTearDown(controller.stop);
    final hosted = await controller.start(party.id);

    // The link is a lan:// link carrying the key the controller persisted.
    final link = PartyJoinLink.parse(hosted.joinLink)!;
    expect(link.relayBaseUrl, 'lan://${hosted.address}:${hosted.port}');
    final key = (await keys.get(party.id))!.keyString;

    // A peer connects over loopback, fetches + decrypts, and votes.
    final channel = await connectToLanHost('127.0.0.1', hosted.port);
    final peer = ChannelPartyRelay(channel);
    addTearDown(peer.dispose);
    final crypto = PartyCrypto.fromKeyString(key);

    final snap = (await peer.fetchParty(party.id))!;
    final decoded = PartyCodec.partyFromJson(await crypto.decryptJson(snap.party));
    expect(decoded.title, 'Where to?');

    final peerBallot =
        Ballot.approval(id: 'peer', party: decoded, approvedOptionIds: const ['b']);
    await peer.submitBallot(party.id, 'peer',
        await crypto.encryptJson(PartyCodec.ballotToJson(peerBallot)));

    // Host folds the peer's encrypted vote into its local tally.
    await controller.syncToLocal();
    final result = await repo.computeResult(party.id) as ApprovalResult;
    expect(result.ballotCount, 2); // host + peer
    expect(result.tallies.firstWhere((t) => t.optionId == 'a').approvals, 1);
    expect(result.tallies.firstWhere((t) => t.optionId == 'b').approvals, 1);
    expect(controller.peerCount, 1);
  });
}
