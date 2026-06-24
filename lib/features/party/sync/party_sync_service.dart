import '../data/local_party_repository.dart';
import '../domain/entities/ballot.dart';
import '../domain/entities/party.dart';
import 'party_codec.dart';
import 'party_crypto.dart';
import 'party_key_store.dart';
import 'party_link.dart';
import 'party_relay.dart';
import 'party_relay_resolver.dart';
import 'transport/channel_relay.dart';

/// Optional remote-participation layer over the local-first party store.
///
/// It encrypts every party/ballot on-device (AES-GCM) before handing the
/// ciphertext to a content-agnostic relay, and decrypts what it pulls back. The
/// relay never sees plaintext; the key travels only inside the share link's URL
/// fragment. The local Drift store remains the source of truth for tallying.
class PartySyncService {
  PartySyncService({
    required LocalPartyRepository local,
    required PartyKeyStore keys,
    required PartyRelayResolver relayFor,
  })  : _local = local,
        _keys = keys,
        _relayFor = relayFor;

  final LocalPartyRepository _local;
  final PartyKeyStore _keys;
  final PartyRelayResolver _relayFor;

  /// One relay per base URL, reused across calls — important for stateful
  /// transports (a LAN socket connects once, not per request).
  final _relays = <String, Future<PartyRelay>>{};

  Future<PartyRelay> _relay(String baseUrl) =>
      _relays.putIfAbsent(baseUrl, () => _relayFor(baseUrl));

  /// Whether [partyId] has been shared/joined (i.e. has a key on this device).
  Future<bool> isSynced(String partyId) async =>
      (await _keys.get(partyId)) != null;

  /// Publish a locally-created party to [relayBaseUrl] and return a join link.
  /// Encrypts the party (and any ballots already cast) with a fresh key.
  Future<String> shareParty(
    String partyId, {
    required String relayBaseUrl,
  }) async {
    final party = await _local.getParty(partyId);
    if (party == null) throw StateError('No local party "$partyId" to share');

    final gen = await PartyCrypto.generate();
    final info = PartySyncInfo(baseUrl: relayBaseUrl, keyString: gen.keyString);
    await _keys.put(partyId, info);

    final relay = await _relay(relayBaseUrl);
    await relay.publishParty(
      partyId,
      await gen.crypto.encryptJson(PartyCodec.partyToJson(party)),
    );

    return PartyJoinLink(
      relayBaseUrl: relayBaseUrl,
      partyId: partyId,
      keyString: gen.keyString,
    ).toUrl();
  }

  /// Join a party from a share link: fetch + decrypt it, store it locally, and
  /// pull any ballots already cast. Returns the joined party.
  Future<Party> joinParty(String url) async {
    final link = PartyJoinLink.parse(url);
    if (link == null) throw ArgumentError('Not a ReckonParty join link');

    final relay = await _relay(link.relayBaseUrl);
    final snap = await relay.fetchParty(link.partyId);
    if (snap == null) throw StateError('Party not found on relay');

    final crypto = PartyCrypto.fromKeyString(link.keyString);
    final party =
        PartyCodec.partyFromJson(await crypto.decryptJson(snap.party));

    await _local.importParty(party);
    await _keys.put(link.partyId,
        PartySyncInfo(baseUrl: link.relayBaseUrl, keyString: link.keyString));
    await _mergeBallots(party, snap, crypto);
    return party;
  }

  /// Push one ballot to the relay (encrypted). No-op for a non-synced party.
  Future<void> pushBallot(String partyId, Ballot ballot) async {
    final info = await _keys.get(partyId);
    if (info == null) return;
    final crypto = PartyCrypto.fromKeyString(info.keyString);
    final relay = await _relay(info.baseUrl);
    await relay.submitBallot(
      partyId,
      ballot.id,
      await crypto.encryptJson(PartyCodec.ballotToJson(ballot)),
    );
  }

  /// Pull remote ballots into the local store (idempotent) and mirror a remote
  /// close. No-op for a non-synced party.
  Future<void> pull(String partyId) async {
    final info = await _keys.get(partyId);
    if (info == null) return;
    final relay = await _relay(info.baseUrl);
    final snap = await relay.fetchParty(partyId);
    if (snap == null) return;
    final party = await _local.getParty(partyId);
    if (party == null) return;

    final crypto = PartyCrypto.fromKeyString(info.keyString);
    await _mergeBallots(party, snap, crypto);
    if (snap.closed && !party.closed) await _local.closeParty(partyId);
  }

  /// Close the party both locally and on the relay.
  Future<void> closeSynced(String partyId) async {
    await _local.closeParty(partyId);
    final info = await _keys.get(partyId);
    if (info != null) {
      final relay = await _relay(info.baseUrl);
      await relay.close(partyId);
    }
  }

  /// Release any transport connections opened by this service (e.g. LAN
  /// sockets). The local store is unaffected.
  Future<void> dispose() async {
    for (final pending in _relays.values) {
      final relay = await pending;
      if (relay is ChannelPartyRelay) await relay.dispose();
    }
    _relays.clear();
  }

  Future<void> _mergeBallots(
      Party party, RelaySnapshot snap, PartyCrypto crypto) async {
    for (final blob in snap.ballots.values) {
      try {
        final ballot =
            PartyCodec.ballotFromJson(await crypto.decryptJson(blob), party);
        await _local.submitBallot(party.id, ballot); // idempotent by id
      } catch (_) {
        // Skip a ballot we can't decrypt or that fails validation rather than
        // poisoning the merge.
      }
    }
  }
}
