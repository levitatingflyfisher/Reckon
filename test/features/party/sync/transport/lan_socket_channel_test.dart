import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/transport/channel_relay.dart';
import 'package:reckon/features/party/sync/transport/duplex_channel.dart';
import 'package:reckon/features/party/sync/transport/lan_socket_channel.dart';

/// Exercises the LAN backend over a *real* loopback TCP socket: framing,
/// reassembly, and the full relay protocol end-to-end.
void main() {
  late LanSocketHost host;

  setUp(() async {
    host = await LanSocketHost.bind(address: '127.0.0.1');
  });

  tearDown(() async {
    await host.close();
  });

  Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);

  test('length framing preserves message boundaries over a stream', () async {
    DuplexChannel? serverSide;
    host.connections.listen((c) => serverSide = c);

    final client = await connectToLanHost('127.0.0.1', host.port);
    // Wait for the server to accept the connection.
    while (serverSide == null) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final received = <String>[];
    serverSide!.incoming.listen((m) => received.add(String.fromCharCodes(m)));

    // Three messages sent back-to-back (likely coalesced in one TCP segment)
    // plus a large one that will span multiple segments.
    client.send(bytes('one'));
    client.send(bytes('two'));
    client.send(bytes('three'));
    final big = String.fromCharCodes(List.filled(200000, 65));
    client.send(bytes(big));

    while (received.length < 4) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(received.sublist(0, 3), ['one', 'two', 'three']);
    expect(received[3].length, 200000);

    await client.close();
  });

  test('full relay protocol round-trips over a real TCP socket', () async {
    // Host attaches a ChannelRelayHost to each accepted peer.
    host.connections.listen((channel) {
      ChannelRelayHost(channel).seed('p1', bytes('CIPHER'));
    });

    final channel = await connectToLanHost('127.0.0.1', host.port);
    final relay = ChannelPartyRelay(channel);

    final snap = (await relay.fetchParty('p1'))!;
    expect(String.fromCharCodes(snap.party), 'CIPHER');

    await relay.submitBallot('p1', 'b1', bytes('VOTE'));
    final after = (await relay.fetchParty('p1'))!;
    expect(after.ballots.keys, contains('b1'));
    expect(String.fromCharCodes(after.ballots['b1']!), 'VOTE');

    await relay.close('p1');
    expect((await relay.fetchParty('p1'))!.closed, isTrue);

    await relay.dispose();
    await channel.close();
  });

  test('connecting to a closed port fails fast', () async {
    final port = host.port;
    await host.close();
    expect(
      connectToLanHost('127.0.0.1', port,
          timeout: const Duration(seconds: 2)),
      throwsA(isA<Exception>()),
    );
  });
}
