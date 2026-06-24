import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/transport/channel_relay.dart';
import 'package:reckon/features/party/sync/transport/duplex_channel.dart';

void main() {
  late ChannelRelayHost host;
  late ChannelPartyRelay client;

  setUp(() {
    final pair = inMemoryChannelPair();
    host = ChannelRelayHost(pair.a);
    client = ChannelPartyRelay(pair.b);
  });

  tearDown(() async {
    await client.dispose();
    await host.dispose();
  });

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  test('fetch of unknown party returns null over the channel', () async {
    expect(await client.fetchParty('nope'), isNull);
  });

  test('publish → fetch round-trips opaque blobs peer-to-peer', () async {
    await client.publishParty('p1', bytes('CIPHER'));
    final snap = (await client.fetchParty('p1'))!;
    expect(utf8.decode(snap.party), 'CIPHER');
    expect(snap.closed, isFalse);
    expect(snap.ballots, isEmpty);
  });

  test('ballots submit, key by id, and round-trip', () async {
    await client.publishParty('p1', bytes('P'));
    await client.submitBallot('p1', 'b1', bytes('V1'));
    await client.submitBallot('p1', 'b2', bytes('V2'));

    final snap = (await client.fetchParty('p1'))!;
    expect(snap.ballots.keys, containsAll(['b1', 'b2']));
    expect(utf8.decode(snap.ballots['b1']!), 'V1');
  });

  test('ballot to unknown party errors', () async {
    expect(client.submitBallot('ghost', 'b1', bytes('V')), throwsStateError);
  });

  test('closing rejects further ballots', () async {
    await client.publishParty('p1', bytes('P'));
    await client.close('p1');
    expect(client.submitBallot('p1', 'late', bytes('V')), throwsStateError);
    expect((await client.fetchParty('p1'))!.closed, isTrue);
  });

  test('a host can seed a party it already owns locally', () async {
    host.seed('p9', bytes('OWNED'));
    final snap = (await client.fetchParty('p9'))!;
    expect(utf8.decode(snap.party), 'OWNED');
  });
}
