import '../data/local_party_repository.dart';
import '../domain/entities/ballot.dart';
import '../domain/entities/party.dart';
import '../domain/repositories/group_repository.dart';
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
///
/// Persistent groups ride the same machinery: a grouped party's blob carries
/// its group manifest ({id, name}) so joiners adopt the group locally, and
/// attributed ballots carry member id + display name so rosters converge
/// device-to-device — all inside the ciphertext, never visible to the relay.
class PartySyncService {
  PartySyncService({
    required LocalPartyRepository local,
    required PartyKeyStore keys,
    required PartyRelayResolver relayFor,
    required GroupRepository groups,
  })  : _local = local,
        _keys = keys,
        _relayFor = relayFor,
        _groups = groups;

  final LocalPartyRepository _local;
  final PartyKeyStore _keys;
  final PartyRelayResolver _relayFor;
  final GroupRepository _groups;

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
      await gen.crypto.encryptJson(
          PartyCodec.partyToJson(party, group: await _manifestFor(party))),
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
    final json = await crypto.decryptJson(snap.party);
    final party = PartyCodec.partyFromJson(json);

    // A grouped decision brings its group along: adopt it locally (idempotent,
    // original id) BEFORE the party import — parties.group_id is a real
    // foreign key.
    final manifest = PartyCodec.groupManifestOf(json);
    if (manifest != null) {
      await _groups.createGroup(name: manifest.name, id: manifest.id);
    }

    await _local.importParty(party);
    await _keys.put(link.partyId,
        PartySyncInfo(baseUrl: link.relayBaseUrl, keyString: link.keyString));
    await _mergeBallots(party, snap, crypto);
    return party;
  }

  /// Push one ballot to the relay (encrypted). No-op for a non-synced party.
  /// An attributed ballot travels with its roster display name (when this
  /// device knows one) so the receiving side can keep its roster current.
  Future<void> pushBallot(String partyId, Ballot ballot) async {
    final info = await _keys.get(partyId);
    if (info == null) return;
    final crypto = PartyCrypto.fromKeyString(info.keyString);
    final relay = await _relay(info.baseUrl);
    await relay.submitBallot(
      partyId,
      ballot.id,
      await crypto.encryptJson(PartyCodec.ballotToJson(
        ballot,
        memberDisplayName: await _displayNameFor(partyId, ballot.memberId),
      )),
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
        final json = await crypto.decryptJson(blob);
        final ballot = PartyCodec.ballotFromJson(json, party);
        // An attributed ballot doubles as roster gossip: learn the member's
        // display name (first name wins; addMember is idempotent).
        final member = PartyCodec.memberOf(json);
        final groupId = party.groupId;
        if (member != null && member.displayName != null && groupId != null) {
          await _groups.addMember(
            groupId: groupId,
            memberId: member.id,
            displayName: member.displayName!,
          );
        }
        await _local.submitBallot(party.id, ballot); // idempotent by id
      } catch (_) {
        // Skip a ballot we can't decrypt or that fails validation rather than
        // poisoning the merge.
      }
    }
  }

  /// The {id, name} manifest for a grouped party, or null when the party is
  /// ungrouped (or its group is unknown locally — then it shares ungrouped
  /// rather than inventing a name).
  Future<({String id, String name})?> _manifestFor(Party party) async {
    final groupId = party.groupId;
    if (groupId == null) return null;
    final group = await _groups.getGroup(groupId);
    if (group == null) return null;
    return (id: group.id, name: group.name);
  }

  /// This device's roster name for [memberId] in the party's group, if any.
  Future<String?> _displayNameFor(String partyId, String? memberId) async {
    if (memberId == null) return null;
    final groupId = (await _local.getParty(partyId))?.groupId;
    if (groupId == null) return null;
    for (final m in await _groups.membersOf(groupId)) {
      if (m.memberId == memberId) return m.displayName;
    }
    return null;
  }
}
