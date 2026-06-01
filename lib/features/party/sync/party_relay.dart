import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A snapshot of a party as the relay holds it: opaque (encrypted) blobs only.
class RelaySnapshot {
  const RelaySnapshot({
    required this.party,
    required this.closed,
    required this.ballots,
  });
  final Uint8List party;
  final bool closed;
  final Map<String, Uint8List> ballots;
}

/// Client side of the ReckonParty relay protocol. Moves opaque, already-encrypted
/// bytes — it has no knowledge of decision content. Implemented by [HttpPartyRelay]
/// (real) and [InMemoryPartyRelay] (tests).
abstract class PartyRelay {
  Future<void> publishParty(String partyId, Uint8List blob);
  Future<RelaySnapshot?> fetchParty(String partyId);
  Future<void> submitBallot(String partyId, String ballotId, Uint8List blob);
  Future<void> close(String partyId);
}

/// Talks to a self-hosted relay over HTTP (see `relay/`).
class HttpPartyRelay implements PartyRelay {
  HttpPartyRelay({required String baseUrl, Dio? dio})
      : _base = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _dio = dio ?? Dio();

  final String _base;
  final Dio _dio;

  static final _bytes = Options(
    responseType: ResponseType.bytes,
    headers: {'content-type': 'application/octet-stream'},
  );

  @override
  Future<void> publishParty(String partyId, Uint8List blob) async {
    await _dio.put<void>('$_base/parties/$partyId',
        data: Stream.value(blob), options: _bytes);
  }

  @override
  Future<RelaySnapshot?> fetchParty(String partyId) async {
    try {
      final res = await _dio.get<String>(
        '$_base/parties/$partyId',
        options: Options(responseType: ResponseType.plain),
      );
      final json = jsonDecode(res.data!) as Map<String, dynamic>;
      return RelaySnapshot(
        party: base64.decode(json['party'] as String),
        closed: (json['closed'] as bool?) ?? false,
        ballots: {
          for (final e in (json['ballots'] as Map).entries)
            e.key as String: base64.decode(e.value as String),
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> submitBallot(
      String partyId, String ballotId, Uint8List blob) async {
    await _dio.put<void>('$_base/parties/$partyId/ballots/$ballotId',
        data: Stream.value(blob), options: _bytes);
  }

  @override
  Future<void> close(String partyId) async {
    await _dio.post<void>('$_base/parties/$partyId/close');
  }
}

/// In-memory relay mirroring the server's semantics, for tests.
class InMemoryPartyRelay implements PartyRelay {
  final Map<String, Uint8List> _parties = {};
  final Map<String, bool> _closed = {};
  final Map<String, Map<String, Uint8List>> _ballots = {};

  @override
  Future<void> publishParty(String partyId, Uint8List blob) async {
    _parties[partyId] = blob;
    _closed.putIfAbsent(partyId, () => false);
    _ballots.putIfAbsent(partyId, () => {});
  }

  @override
  Future<RelaySnapshot?> fetchParty(String partyId) async {
    final party = _parties[partyId];
    if (party == null) return null;
    return RelaySnapshot(
      party: party,
      closed: _closed[partyId] ?? false,
      ballots: Map.of(_ballots[partyId] ?? {}),
    );
  }

  @override
  Future<void> submitBallot(
      String partyId, String ballotId, Uint8List blob) async {
    if (!_parties.containsKey(partyId)) {
      throw StateError('unknown party');
    }
    if (_closed[partyId] ?? false) throw StateError('party closed');
    (_ballots[partyId] ??= {})[ballotId] = blob;
  }

  @override
  Future<void> close(String partyId) async => _closed[partyId] = true;

  /// Test helper: the raw stored bytes for a ballot (to assert it's ciphertext).
  Uint8List? rawBallot(String partyId, String ballotId) =>
      _ballots[partyId]?[ballotId];
}
