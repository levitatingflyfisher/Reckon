import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/party_relay.dart';

/// Serves a fixed body via a fake transport, so we can hand fetchParty an
/// arbitrary "relay" response without a socket. The join link controls the
/// relay host, so every byte of that response is untrusted input.
class _FixedBodyAdapter implements HttpClientAdapter {
  _FixedBodyAdapter(this.body);
  final List<int> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async =>
      ResponseBody.fromBytes(Uint8List.fromList(body), 200);

  @override
  void close({bool force = false}) {}
}

HttpPartyRelay _relayServing(List<int> body) {
  final dio = Dio()..httpClientAdapter = _FixedBodyAdapter(body);
  return HttpPartyRelay(baseUrl: 'http://relay.test', dio: dio);
}

/// A corrupt relay response must surface as the flow's normal failure mode
/// (a [DioException], like every other transport-level failure), never as an
/// unhandled [FormatException]/[TypeError] escaping the decode path — the
/// same trust-boundary stance ChannelPartyRelay takes by dropping frames it
/// cannot decode.
void main() {
  test('fetchParty surfaces non-JSON relay bytes as a DioException', () async {
    final relay = _relayServing(utf8.encode('this is }{ not JSON'));

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<DioException>()),
      reason: 'malformed JSON from an untrusted relay must map to the typed '
          'transport failure, not leak a FormatException',
    );
  });

  test('fetchParty surfaces wrong-shape JSON (top level) as a DioException',
      () async {
    // Valid JSON, but a list where the snapshot object should be.
    final relay = _relayServing(utf8.encode(jsonEncode([1, 2, 3])));

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<DioException>()),
      reason: 'a non-object body must map to the typed transport failure, '
          'not leak a TypeError from the cast',
    );
  });

  test('fetchParty surfaces wrong-shape JSON (bad field types) as a '
      'DioException', () async {
    // An object, but `party` is a number and `ballots` is missing.
    final relay = _relayServing(utf8.encode(jsonEncode({'party': 42})));

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<DioException>()),
      reason: 'wrong field types must map to the typed transport failure, '
          'not leak a TypeError from the casts',
    );
  });

  test('fetchParty surfaces invalid base64 blobs as a DioException', () async {
    final relay = _relayServing(utf8.encode(jsonEncode({
      'party': '!!!not-base64!!!',
      'closed': false,
      'ballots': <String, dynamic>{},
    })));

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<DioException>()),
      reason: 'invalid base64 must map to the typed transport failure, not '
          'leak a FormatException from base64.decode',
    );
  });

  test('fetchParty surfaces a bad ballot blob as a DioException', () async {
    final relay = _relayServing(utf8.encode(jsonEncode({
      'party': base64.encode([1, 2, 3]),
      'closed': false,
      'ballots': {'b1': 'not/base64!!'},
    })));

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<DioException>()),
      reason: 'a corrupt ballot entry must map to the typed transport '
          'failure like every other malformed field',
    );
  });

  test('a well-formed snapshot still decodes after the guard', () async {
    final party = base64.encode([9, 9, 9]);
    final ballot = base64.encode([7]);
    final relay = _relayServing(utf8.encode(jsonEncode({
      'party': party,
      'closed': true,
      'ballots': {'b1': ballot},
    })));

    final snap = (await relay.fetchParty('p1'))!;
    expect(snap.party, [9, 9, 9]);
    expect(snap.closed, isTrue);
    expect(snap.ballots['b1'], [7]);
  });
}
