import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/transport/channel_relay.dart';
import 'package:reckon/features/party/sync/transport/lan_party_host.dart';
import 'package:reckon/features/party/sync/transport/lan_socket_channel.dart';

/// Two guests on one LAN host, sharing a single store: a ballot from one guest
/// is visible to the other — the multi-peer consistency the shared store fixes.
void main() {
  Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);

  test('a ballot from one LAN guest is seen by another guest', () async {
    final host = await LanPartyHost.start(
      partyId: 'p1',
      partyBlob: bytes('CIPHER'),
      address: '127.0.0.1',
    );
    addTearDown(host.stop);

    final guestA = ChannelPartyRelay(
        await connectToLanHost('127.0.0.1', host.port));
    final guestB = ChannelPartyRelay(
        await connectToLanHost('127.0.0.1', host.port));
    addTearDown(guestA.dispose);
    addTearDown(guestB.dispose);

    // Both guests fetch the same party from the shared store.
    expect(String.fromCharCodes((await guestA.fetchParty('p1'))!.party),
        'CIPHER');
    expect(String.fromCharCodes((await guestB.fetchParty('p1'))!.party),
        'CIPHER');

    // Guest A votes; Guest B sees it.
    await guestA.submitBallot('p1', 'a-ballot', bytes('VOTE_A'));
    final seenByB = (await guestB.fetchParty('p1'))!;
    expect(seenByB.ballots.keys, contains('a-ballot'));
    expect(String.fromCharCodes(seenByB.ballots['a-ballot']!), 'VOTE_A');

    // The host counts both peers.
    expect(host.peerCount, 2);
  });
}
