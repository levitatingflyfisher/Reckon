/// Hosts a party on the local network: binds a [LanSocketHost] and serves every
/// connecting peer from one shared [PartyBlobStore], so all guests see the same
/// ballots. Mobile/desktop only (`dart:io` via [LanSocketHost]).
library;

import 'dart:async';
import 'dart:typed_data';

import 'channel_relay.dart';
import 'lan_socket_channel.dart';

class LanPartyHost {
  LanPartyHost._(this._socket, this.store);

  final LanSocketHost _socket;

  /// The shared store backing every peer connection. Seed it (the creator's
  /// encrypted party + ballots) before or after guests join.
  final PartyBlobStore store;

  final _peers = <ChannelRelayHost>[];
  StreamSubscription? _sub;

  /// Start hosting [partyId] (opaque [partyBlob] + any [ballotBlobs]) on the
  /// LAN. Read [port] afterwards to put in the share link / QR.
  static Future<LanPartyHost> start({
    required String partyId,
    required Uint8List partyBlob,
    Map<String, Uint8List> ballotBlobs = const {},
    Object address = '0.0.0.0',
    int port = 0,
  }) async {
    final socket = await LanSocketHost.bind(address: address, port: port);
    final store = PartyBlobStore()
      ..seed(partyId, partyBlob, ballotBlobs: ballotBlobs);
    final host = LanPartyHost._(socket, store);
    host._sub = socket.connections.listen(
      (channel) => host._peers.add(ChannelRelayHost(channel, store: store)),
    );
    return host;
  }

  /// The bound TCP port guests connect to.
  int get port => _socket.port;

  /// Number of peers currently attached (diagnostics / UI).
  int get peerCount => _peers.length;

  Future<void> stop() async {
    await _sub?.cancel();
    for (final peer in _peers) {
      await peer.dispose();
    }
    await _socket.close();
  }
}
