import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:reckonparty_relay/relay.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';

void main() {
  late dynamic server;
  late String base;

  setUp(() async {
    server = await io.serve(createRelayHandler(InMemoryBlobStore()), 'localhost', 0);
    base = 'http://localhost:${server.port}';
  });

  tearDown(() async => server.close(force: true));

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  test('healthz responds ok', () async {
    final r = await http.get(Uri.parse('$base/healthz'));
    expect(r.statusCode, 200);
  });

  test('GET unknown party is 404', () async {
    final r = await http.get(Uri.parse('$base/parties/nope'));
    expect(r.statusCode, 404);
  });

  test('publish then fetch round-trips the opaque party blob', () async {
    final put = await http.put(Uri.parse('$base/parties/p1'), body: bytes('CIPHERTEXT'));
    expect(put.statusCode, 200);

    final get = await http.get(Uri.parse('$base/parties/p1'));
    expect(get.statusCode, 200);
    final json = jsonDecode(get.body) as Map<String, dynamic>;
    expect(utf8.decode(base64.decode(json['party'] as String)), 'CIPHERTEXT');
    expect(json['closed'], false);
    expect(json['ballots'], isEmpty);
  });

  test('ballots append, are keyed by id, and round-trip', () async {
    await http.put(Uri.parse('$base/parties/p1'), body: bytes('P'));
    await http.put(Uri.parse('$base/parties/p1/ballots/b1'), body: bytes('V1'));
    await http.put(Uri.parse('$base/parties/p1/ballots/b2'), body: bytes('V2'));

    final json = jsonDecode((await http.get(Uri.parse('$base/parties/p1'))).body)
        as Map<String, dynamic>;
    final ballots = (json['ballots'] as Map).cast<String, dynamic>();
    expect(ballots.keys, containsAll(['b1', 'b2']));
    expect(utf8.decode(base64.decode(ballots['b1'] as String)), 'V1');
  });

  test('ballot to an unknown party is 404', () async {
    final r = await http.put(Uri.parse('$base/parties/ghost/ballots/b1'),
        body: bytes('V'));
    expect(r.statusCode, 404);
  });

  test('resubmitting the same ballot id overwrites (idempotent)', () async {
    await http.put(Uri.parse('$base/parties/p1'), body: bytes('P'));
    await http.put(Uri.parse('$base/parties/p1/ballots/b1'), body: bytes('first'));
    await http.put(Uri.parse('$base/parties/p1/ballots/b1'), body: bytes('second'));

    final json = jsonDecode((await http.get(Uri.parse('$base/parties/p1'))).body)
        as Map<String, dynamic>;
    final ballots = (json['ballots'] as Map).cast<String, dynamic>();
    expect(ballots.length, 1);
    expect(utf8.decode(base64.decode(ballots['b1'] as String)), 'second');
  });

  test('closing a party rejects further ballots with 409', () async {
    await http.put(Uri.parse('$base/parties/p1'), body: bytes('P'));
    final close = await http.post(Uri.parse('$base/parties/p1/close'));
    expect(close.statusCode, 200);

    final r = await http.put(Uri.parse('$base/parties/p1/ballots/late'),
        body: bytes('V'));
    expect(r.statusCode, 409);

    final json = jsonDecode((await http.get(Uri.parse('$base/parties/p1'))).body)
        as Map<String, dynamic>;
    expect(json['closed'], true);
  });

  test('oversized blob is rejected with 413', () async {
    final big = Uint8List(256 * 1024 + 1);
    final r = await http.put(Uri.parse('$base/parties/p1'), body: big);
    expect(r.statusCode, 413);
  });

  test('GET /v/{id} serves the web ballot page as HTML', () async {
    final r = await http.get(Uri.parse('$base/v/any-party-id'));
    expect(r.statusCode, 200);
    expect(r.headers['content-type'], contains('text/html'));
    // The page is the encrypted, no-account voting surface.
    expect(r.body, contains('<title>ReckonParty'));
    expect(r.body, contains('AES-GCM')); // client-side crypto present
    expect(r.body, contains('/parties/')); // fetches the blob from the relay
  });
}
