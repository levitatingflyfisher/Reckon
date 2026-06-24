@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/party_relay.dart';
import 'package:reckonparty_relay/relay.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// End-to-end check that [HttpPartyRelay] (the dio client) speaks the real
/// relay server's wire protocol, run in-process over a real socket.
void main() {
  late HttpServer server;
  late HttpPartyRelay relay;

  setUp(() async {
    // The shared flutter_test_config.dart initialises TestWidgetsFlutterBinding
    // (to load fonts for the golden tests), which installs an HttpOverrides that
    // stubs every real HTTP request to status 400. This end-to-end test talks to
    // an in-process relay over a real loopback socket, so opt out of that
    // override for this VM test.
    HttpOverrides.global = null;
    server = await shelf_io.serve(
        createRelayHandler(InMemoryBlobStore()), 'localhost', 0);
    relay = HttpPartyRelay(baseUrl: 'http://localhost:${server.port}');
  });

  tearDown(() async => server.close(force: true));

  Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);

  test('publish, fetch, ballot, and close over real HTTP', () async {
    expect(await relay.fetchParty('p1'), isNull);

    await relay.publishParty('p1', bytes('PARTY_BLOB'));
    await relay.submitBallot('p1', 'b1', bytes('BALLOT_1'));
    await relay.submitBallot('p1', 'b2', bytes('BALLOT_2'));

    final snap = (await relay.fetchParty('p1'))!;
    expect(String.fromCharCodes(snap.party), 'PARTY_BLOB');
    expect(snap.closed, isFalse);
    expect(snap.ballots.keys, containsAll(['b1', 'b2']));
    expect(String.fromCharCodes(snap.ballots['b1']!), 'BALLOT_1');

    await relay.close('p1');
    expect((await relay.fetchParty('p1'))!.closed, isTrue);
  });
}
