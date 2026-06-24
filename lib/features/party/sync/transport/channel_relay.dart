/// The relay protocol spoken over a [DuplexChannel] as request/response JSON
/// messages. This is the shared engine for every peer-to-peer transport (LAN,
/// Nearby, WebRTC): only the underlying channel differs. It mirrors the HTTP
/// relay's semantics exactly, so `PartySyncService` behaves identically whether
/// it talks to a cloud relay or a peer.
///
/// Message shape:
///   request : {"rid", "op": publish|get|ballot|close, "partyId",
///              "ballotId"?, "blob"? (base64)}
///   response: {"rid", "ok": bool, "error"?, "snapshot"? {party, closed,
///              ballots:{id:blob}}}
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../party_relay.dart';
import 'duplex_channel.dart';

/// Client side: implements [PartyRelay] by sending requests to a peer that runs
/// a [ChannelRelayHost], and awaiting correlated responses.
class ChannelPartyRelay implements PartyRelay {
  ChannelPartyRelay(this._channel, {Uuid? uuid, Duration? timeout})
      : _uuid = uuid ?? const Uuid(),
        _timeout = timeout ?? const Duration(seconds: 15) {
    _sub = _channel.incoming.listen(_onMessage);
  }

  final DuplexChannel _channel;
  final Uuid _uuid;
  final Duration _timeout;
  late final StreamSubscription<Uint8List> _sub;
  final _pending = <String, Completer<Map<String, dynamic>>>{};

  void _onMessage(Uint8List bytes) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final rid = msg['rid'] as String?;
    if (rid == null) return;
    _pending.remove(rid)?.complete(msg);
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> req) {
    final rid = _uuid.v4();
    req['rid'] = rid;
    final completer = Completer<Map<String, dynamic>>();
    _pending[rid] = completer;
    _channel.send(Uint8List.fromList(utf8.encode(jsonEncode(req))));
    return completer.future.timeout(_timeout, onTimeout: () {
      _pending.remove(rid);
      throw TimeoutException('Peer did not respond', _timeout);
    });
  }

  void _check(Map<String, dynamic> res) {
    if (res['ok'] != true) {
      throw StateError((res['error'] as String?) ?? 'peer error');
    }
  }

  @override
  Future<void> publishParty(String partyId, Uint8List blob) async {
    _check(await _request({
      'op': 'publish',
      'partyId': partyId,
      'blob': base64.encode(blob),
    }));
  }

  @override
  Future<RelaySnapshot?> fetchParty(String partyId) async {
    final res = await _request({'op': 'get', 'partyId': partyId});
    if (res['ok'] != true) return null;
    final snap = res['snapshot'] as Map<String, dynamic>?;
    if (snap == null) return null;
    return RelaySnapshot(
      party: base64.decode(snap['party'] as String),
      closed: (snap['closed'] as bool?) ?? false,
      ballots: {
        for (final e in (snap['ballots'] as Map).entries)
          e.key as String: base64.decode(e.value as String),
      },
    );
  }

  @override
  Future<void> submitBallot(
      String partyId, String ballotId, Uint8List blob) async {
    _check(await _request({
      'op': 'ballot',
      'partyId': partyId,
      'ballotId': ballotId,
      'blob': base64.encode(blob),
    }));
  }

  @override
  Future<void> close(String partyId) async {
    _check(await _request({'op': 'close', 'partyId': partyId}));
  }

  Future<void> dispose() async {
    await _sub.cancel();
    for (final c in _pending.values) {
      c.completeError(StateError('channel disposed'));
    }
    _pending.clear();
  }
}

/// In-memory store of opaque party/ballot blobs and the relay protocol logic
/// over them. It never decrypts anything — same zero-knowledge stance as the
/// HTTP relay. A single store can be shared by many [ChannelRelayHost]s (one
/// per connected peer) so every LAN/Nearby peer sees the same ballots.
class PartyBlobStore {
  final _parties = <String, Uint8List>{};
  final _closed = <String, bool>{};
  final _ballots = <String, Map<String, Uint8List>>{};

  /// Seed a party this device already holds locally (the host is the creator).
  /// [partyBlob] and [ballotBlobs] are opaque ciphertext.
  void seed(String partyId, Uint8List partyBlob,
      {Map<String, Uint8List> ballotBlobs = const {}}) {
    _parties[partyId] = partyBlob;
    _closed.putIfAbsent(partyId, () => false);
    _ballots[partyId] = {...?_ballots[partyId], ...ballotBlobs};
  }

  /// The opaque ballot blobs peers have submitted for [partyId] (the LAN host
  /// decrypts these into its local store to tally).
  Map<String, Uint8List> ballotsOf(String partyId) =>
      Map.unmodifiable(_ballots[partyId] ?? const {});

  /// Whether [partyId] has been closed on this store.
  bool isClosed(String partyId) => _closed[partyId] ?? false;

  /// Apply one decoded request and produce the response body (without `rid`).
  Map<String, dynamic> handle(Map<String, dynamic> msg) {
    final op = msg['op'] as String;
    final partyId = msg['partyId'] as String?;
    if (partyId == null) return {'ok': false, 'error': 'missing partyId'};

    switch (op) {
      case 'publish':
        _parties[partyId] = base64.decode(msg['blob'] as String);
        _closed.putIfAbsent(partyId, () => false);
        _ballots.putIfAbsent(partyId, () => {});
        return {'ok': true};

      case 'get':
        final party = _parties[partyId];
        if (party == null) return {'ok': false, 'error': 'unknown party'};
        return {
          'ok': true,
          'snapshot': {
            'party': base64.encode(party),
            'closed': _closed[partyId] ?? false,
            'ballots': {
              for (final e in (_ballots[partyId] ?? {}).entries)
                e.key: base64.encode(e.value),
            },
          },
        };

      case 'ballot':
        if (!_parties.containsKey(partyId)) {
          return {'ok': false, 'error': 'unknown party'};
        }
        if (_closed[partyId] ?? false) {
          return {'ok': false, 'error': 'party closed'};
        }
        final ballotId = msg['ballotId'] as String?;
        if (ballotId == null) return {'ok': false, 'error': 'missing ballotId'};
        (_ballots[partyId] ??= {})[ballotId] = base64.decode(msg['blob'] as String);
        return {'ok': true};

      case 'close':
        if (!_parties.containsKey(partyId)) {
          return {'ok': false, 'error': 'unknown party'};
        }
        _closed[partyId] = true;
        return {'ok': true};

      default:
        return {'ok': false, 'error': 'unknown op'};
    }
  }
}

/// Host side: answers a single peer's requests over one [DuplexChannel],
/// backed by a [PartyBlobStore]. Pass a shared store to serve many peers
/// consistently (e.g. a LAN host with several guests).
class ChannelRelayHost {
  ChannelRelayHost(this._channel, {PartyBlobStore? store})
      : store = store ?? PartyBlobStore() {
    _sub = _channel.incoming.listen(_onMessage);
  }

  final DuplexChannel _channel;
  final PartyBlobStore store;
  late final StreamSubscription<Uint8List> _sub;

  void _onMessage(Uint8List bytes) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final rid = msg['rid'];
    if (rid is! String || msg['op'] is! String) return;
    final reply = store.handle(msg)..['rid'] = rid;
    _channel.send(Uint8List.fromList(utf8.encode(jsonEncode(reply))));
  }

  /// Convenience: seed the underlying store. See [PartyBlobStore.seed].
  void seed(String partyId, Uint8List partyBlob,
          {Map<String, Uint8List> ballotBlobs = const {}}) =>
      store.seed(partyId, partyBlob, ballotBlobs: ballotBlobs);

  Future<void> dispose() => _sub.cancel();
}
