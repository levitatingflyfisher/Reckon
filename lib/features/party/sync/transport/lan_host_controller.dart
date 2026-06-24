/// Drives hosting a party on the local network from the creator's device:
/// encrypts the party, starts a [LanPartyHost], generates the `lan://` join
/// link, and bridges ballots peers submit back into the local store so the
/// host can tally them. Mobile/desktop only (`dart:io`).
library;

import 'dart:io';
import 'dart:typed_data';

import '../../data/local_party_repository.dart';
import '../party_codec.dart';
import '../party_crypto.dart';
import '../party_key_store.dart';
import '../party_link.dart';
import 'lan_party_host.dart';

/// What the UI needs to invite others: the link (also rendered as a QR) and the
/// address peers connect to.
class HostedLanParty {
  const HostedLanParty(
      {required this.joinLink, required this.address, required this.port});
  final String joinLink;
  final String address;
  final int port;
}

class LanHostController {
  LanHostController(this._local, this._keys);

  final LocalPartyRepository _local;
  final PartyKeyStore _keys;

  LanPartyHost? _host;
  PartyCrypto? _crypto;
  String? _partyId;

  bool get isHosting => _host != null;
  int get peerCount => _host?.peerCount ?? 0;

  /// Start hosting [partyId] on the LAN. Generates a fresh key, encrypts the
  /// party (and any ballots already cast locally), seeds the host, persists the
  /// sync key, and returns the share link.
  Future<HostedLanParty> start(String partyId) async {
    if (_host != null) throw StateError('Already hosting a party');
    final party = await _local.getParty(partyId);
    if (party == null) throw StateError('No local party "$partyId" to host');

    final gen = await PartyCrypto.generate();
    final partyBlob = await gen.crypto.encryptJson(PartyCodec.partyToJson(party));
    final ballotBlobs = <String, Uint8List>{};
    for (final b in await _local.getBallots(partyId)) {
      ballotBlobs[b.id] = await gen.crypto.encryptJson(PartyCodec.ballotToJson(b));
    }

    final address = await _lanAddress();
    final host = await LanPartyHost.start(
      partyId: partyId,
      partyBlob: partyBlob,
      ballotBlobs: ballotBlobs,
    );

    final baseUrl = 'lan://$address:${host.port}';
    await _keys.put(partyId,
        PartySyncInfo(baseUrl: baseUrl, keyString: gen.keyString));

    _host = host;
    _crypto = gen.crypto;
    _partyId = partyId;

    return HostedLanParty(
      joinLink: PartyJoinLink(
        relayBaseUrl: baseUrl,
        partyId: partyId,
        keyString: gen.keyString,
      ).toUrl(),
      address: address,
      port: host.port,
    );
  }

  /// Decrypt ballots peers submitted and merge them into the local store
  /// (idempotent). Call this to refresh the host's tally as votes arrive.
  Future<void> syncToLocal() async {
    final host = _host;
    final crypto = _crypto;
    final id = _partyId;
    if (host == null || crypto == null || id == null) return;
    final party = await _local.getParty(id);
    if (party == null) return;
    for (final blob in host.store.ballotsOf(id).values) {
      try {
        final ballot =
            PartyCodec.ballotFromJson(await crypto.decryptJson(blob), party);
        await _local.submitBallot(id, ballot);
      } catch (_) {
        // Skip anything that won't decrypt/validate rather than poison the tally.
      }
    }
  }

  Future<void> stop() async {
    await _host?.stop();
    _host = null;
    _crypto = null;
    _partyId = null;
  }

  /// First non-loopback IPv4 address, so LAN peers can reach the host. Falls
  /// back to loopback (useful in tests / single-device).
  static Future<String> _lanAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return InternetAddress.loopbackIPv4.address;
  }
}
