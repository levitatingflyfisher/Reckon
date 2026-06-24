import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ballot_page.dart';

/// Storage boundary for the relay. The relay only ever moves **opaque bytes**:
/// a party blob and a set of ballot blobs, keyed by ids the client chooses.
/// Implementations must not interpret blob contents. Swap [InMemoryBlobStore]
/// for a file/Redis/Postgres-backed store to make a deployment durable.
abstract class BlobStore {
  Future<bool> exists(String partyId);
  Future<void> putParty(String partyId, Uint8List blob);
  Future<PartyBlobs?> getParty(String partyId);
  Future<bool> putBallot(String partyId, String ballotId, Uint8List blob);
  Future<bool> close(String partyId);
}

/// What a relay knows about one party: an opaque party blob, whether it's been
/// closed, and the opaque ballot blobs submitted so far (keyed by ballot id).
class PartyBlobs {
  PartyBlobs({required this.party, required this.closed, required this.ballots});
  final Uint8List party;
  final bool closed;
  final Map<String, Uint8List> ballots;
}

class _Entry {
  _Entry(this.party);
  Uint8List party;
  bool closed = false;
  final Map<String, Uint8List> ballots = {};
}

/// Process-memory store. Fine for a small/ephemeral relay (parties expire in a
/// week anyway); not durable across restarts.
class InMemoryBlobStore implements BlobStore {
  final Map<String, _Entry> _parties = {};

  @override
  Future<bool> exists(String partyId) async => _parties.containsKey(partyId);

  @override
  Future<void> putParty(String partyId, Uint8List blob) async {
    final existing = _parties[partyId];
    if (existing == null) {
      _parties[partyId] = _Entry(blob);
    } else {
      existing.party = blob; // creator may re-publish (e.g. edited options)
    }
  }

  @override
  Future<PartyBlobs?> getParty(String partyId) async {
    final e = _parties[partyId];
    if (e == null) return null;
    return PartyBlobs(
      party: e.party,
      closed: e.closed,
      ballots: Map.of(e.ballots),
    );
  }

  @override
  Future<bool> putBallot(String partyId, String ballotId, Uint8List blob) async {
    final e = _parties[partyId];
    if (e == null) return false;
    if (e.closed) return false;
    e.ballots[ballotId] = blob; // idempotent by ballot id; last write wins
    return true;
  }

  @override
  Future<bool> close(String partyId) async {
    final e = _parties[partyId];
    if (e == null) return false;
    e.closed = true;
    return true;
  }
}

/// Maximum accepted blob size (256 KB). A ballot/party blob is tiny; this just
/// caps abuse.
const _maxBlobBytes = 256 * 1024;

/// Builds the relay's HTTP handler over [store].
///
/// Protocol (all blobs are opaque, client-encrypted bytes):
///   * `GET  /healthz`                       — liveness.
///   * `GET  /v/{id}`                         — no-account web ballot page (HTML).
///   * `PUT  /parties/{id}`                   — publish/replace the party blob.
///   * `GET  /parties/{id}`                   — `{party, closed, ballots:{id:blob}}`
///                                              (blobs base64); 404 if unknown.
///   * `PUT  /parties/{id}/ballots/{ballotId}`— append/replace a ballot blob
///                                              (404 if party unknown, 409 if closed).
///   * `POST /parties/{id}/close`             — close voting (404 if unknown).
Handler createRelayHandler(BlobStore store) {
  final router = Router();

  router.get('/healthz', (Request _) => Response.ok('ok'));

  // No-account web ballot page. The party id is in the path and the decryption
  // key in the URL fragment (never sent here); all crypto runs in the browser.
  router.get('/v/<id>', (Request _, String id) {
    return Response.ok(ballotPageHtml,
        headers: {'content-type': 'text/html; charset=utf-8'});
  });

  router.put('/parties/<id>', (Request req, String id) async {
    final body = await _readBounded(req);
    if (body == null) return _tooLarge();
    await store.putParty(id, body);
    return Response.ok('{"ok":true}', headers: _json);
  });

  router.get('/parties/<id>', (Request _, String id) async {
    final blobs = await store.getParty(id);
    if (blobs == null) return Response.notFound('{"error":"unknown party"}',
        headers: _json);
    final payload = {
      'party': base64.encode(blobs.party),
      'closed': blobs.closed,
      'ballots': {
        for (final e in blobs.ballots.entries) e.key: base64.encode(e.value),
      },
    };
    return Response.ok(jsonEncode(payload), headers: _json);
  });

  router.put('/parties/<id>/ballots/<ballotId>',
      (Request req, String id, String ballotId) async {
    final body = await _readBounded(req);
    if (body == null) return _tooLarge();
    if (!await store.exists(id)) {
      return Response.notFound('{"error":"unknown party"}', headers: _json);
    }
    final ok = await store.putBallot(id, ballotId, body);
    if (!ok) {
      return Response(409,
          body: '{"error":"party closed"}', headers: _json);
    }
    return Response.ok('{"ok":true}', headers: _json);
  });

  router.post('/parties/<id>/close', (Request _, String id) async {
    if (!await store.close(id)) {
      return Response.notFound('{"error":"unknown party"}', headers: _json);
    }
    return Response.ok('{"ok":true}', headers: _json);
  });

  return router.call;
}

const _json = {'content-type': 'application/json'};

Response _tooLarge() =>
    Response(413, body: '{"error":"blob too large"}', headers: _json);

/// Reads a request body, returning null if it exceeds [_maxBlobBytes].
Future<Uint8List?> _readBounded(Request req) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in req.read()) {
    builder.add(chunk);
    if (builder.length > _maxBlobBytes) return null;
  }
  return builder.takeBytes();
}
