import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/party_relay.dart';

/// Serves a fixed body via a fake transport, so we can hand fetchParty an
/// oversized response from an "untrusted relay" without a socket.
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

void main() {
  test('fetchParty rejects an over-cap relay response even when it is valid JSON',
      () async {
    // A well-formed RelaySnapshot body, but ~1.9 MB — over the 1 MB cap. The
    // join link controls the relay host, so its body size is untrusted; without
    // a cap fetchParty would buffer and decode the whole thing (OOM vector).
    final body = utf8.encode(jsonEncode({
      'party': base64.encode(Uint8List(1400000)),
      'closed': false,
      'ballots': <String, dynamic>{},
    }));
    final dio = Dio()..httpClientAdapter = _FixedBodyAdapter(body);
    final relay = HttpPartyRelay(baseUrl: 'http://relay.test', dio: dio);

    await expectLater(
      () => relay.fetchParty('p1'),
      throwsA(isA<DioException>()),
      reason: 'the cap must abort the read before decoding an oversized body',
    );
  });
}
