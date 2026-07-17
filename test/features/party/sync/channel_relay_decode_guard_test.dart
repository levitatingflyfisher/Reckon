import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/transport/channel_relay.dart';
import 'package:reckon/features/party/sync/transport/duplex_channel.dart';

/// Answers every request arriving on [peer] with `ok: true` and the given
/// snapshot value verbatim — a stand-in for a malicious or corrupt peer. The
/// peer device fully controls these bytes, so every field of the snapshot is
/// untrusted input, exactly like the HTTP relay's response body.
void _answerWithSnapshot(DuplexChannel peer, Object? snapshot) {
  peer.incoming.listen((bytes) {
    final req = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    peer.send(Uint8List.fromList(utf8.encode(jsonEncode({
      'rid': req['rid'],
      'ok': true,
      'snapshot': snapshot,
    }))));
  });
}

/// A malformed peer snapshot must surface as the channel flow's normal
/// failure mode (a [StateError], like every peer-reported error from
/// `_check`), never as an unhandled [FormatException]/[TypeError] escaping
/// the decode path — the same trust-boundary stance HttpPartyRelay.fetchParty
/// takes with the relay body.
void main() {
  test('fetchParty surfaces a non-map snapshot as a StateError', () async {
    final pair = inMemoryChannelPair();
    _answerWithSnapshot(pair.b, [1, 2, 3]);
    final relay = ChannelPartyRelay(pair.a);

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<StateError>()),
      reason: 'a snapshot that is not an object must map to the typed flow '
          'failure, not leak a TypeError from the cast',
    );
    await relay.dispose();
  });

  test('fetchParty surfaces wrong field types as a StateError', () async {
    final pair = inMemoryChannelPair();
    // An object, but `party` is a number and `ballots` is missing.
    _answerWithSnapshot(pair.b, {'party': 42});
    final relay = ChannelPartyRelay(pair.a);

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<StateError>()),
      reason: 'wrong field types must map to the typed flow failure, not '
          'leak a TypeError from the casts',
    );
    await relay.dispose();
  });

  test('fetchParty surfaces an invalid base64 party blob as a StateError',
      () async {
    final pair = inMemoryChannelPair();
    _answerWithSnapshot(pair.b, {
      'party': '!!!not-base64!!!',
      'closed': false,
      'ballots': <String, dynamic>{},
    });
    final relay = ChannelPartyRelay(pair.a);

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<StateError>()),
      reason: 'invalid base64 must map to the typed flow failure, not leak '
          'a FormatException from base64.decode',
    );
    await relay.dispose();
  });

  test('fetchParty surfaces a bad ballot blob as a StateError', () async {
    final pair = inMemoryChannelPair();
    _answerWithSnapshot(pair.b, {
      'party': base64.encode([1, 2, 3]),
      'closed': false,
      'ballots': {'b1': 'not/base64!!'},
    });
    final relay = ChannelPartyRelay(pair.a);

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<StateError>()),
      reason: 'a corrupt ballot entry must map to the typed flow failure '
          'like every other malformed field',
    );
    await relay.dispose();
  });

  test('a null snapshot still means "no party" after the guard', () async {
    final pair = inMemoryChannelPair();
    _answerWithSnapshot(pair.b, null);
    final relay = ChannelPartyRelay(pair.a);

    expect(await relay.fetchParty('p1'), isNull);
    await relay.dispose();
  });

  test('a well-formed snapshot still decodes after the guard', () async {
    final pair = inMemoryChannelPair();
    _answerWithSnapshot(pair.b, {
      'party': base64.encode([9, 9, 9]),
      'closed': true,
      'ballots': {'b1': base64.encode([7])},
    });
    final relay = ChannelPartyRelay(pair.a);

    final snap = (await relay.fetchParty('p1'))!;
    expect(snap.party, [9, 9, 9]);
    expect(snap.closed, isTrue);
    expect(snap.ballots['b1'], [7]);
    await relay.dispose();
  });
}
