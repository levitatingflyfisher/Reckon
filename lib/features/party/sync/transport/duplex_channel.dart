import 'dart:async';
import 'dart:typed_data';

/// A bidirectional, message-oriented byte pipe between two devices.
///
/// This is the single seam every peer-to-peer transport plugs into: LAN
/// sockets, Android Nearby Connections, and WebRTC data channels all become a
/// [DuplexChannel], and the relay protocol ([ChannelPartyRelay] /
/// `ChannelRelayHost`) runs over it unchanged. Implementations must preserve
/// **message boundaries** (each [send] arrives as exactly one [incoming]
/// event) — Nearby and WebRTC do this natively; a raw-socket adapter must add
/// length framing.
abstract class DuplexChannel {
  /// Messages arriving from the peer. Broadcast so host + client logic and
  /// diagnostics can listen independently.
  Stream<Uint8List> get incoming;

  /// Send one message to the peer.
  void send(Uint8List message);

  /// Tear down the channel.
  Future<void> close();
}

/// Two in-memory channels wired to each other — `pair.a` ↔ `pair.b`. Used in
/// tests to exercise the full relay protocol with no real transport, and as a
/// reference for what a backend adapter must provide.
({DuplexChannel a, DuplexChannel b}) inMemoryChannelPair() {
  final aIn = StreamController<Uint8List>.broadcast();
  final bIn = StreamController<Uint8List>.broadcast();
  final a = _PipeChannel(incomingCtrl: aIn, outgoingCtrl: bIn);
  final b = _PipeChannel(incomingCtrl: bIn, outgoingCtrl: aIn);
  return (a: a, b: b);
}

class _PipeChannel implements DuplexChannel {
  _PipeChannel({required this.incomingCtrl, required this.outgoingCtrl});

  final StreamController<Uint8List> incomingCtrl;
  final StreamController<Uint8List> outgoingCtrl;

  @override
  Stream<Uint8List> get incoming => incomingCtrl.stream;

  @override
  void send(Uint8List message) {
    if (!outgoingCtrl.isClosed) outgoingCtrl.add(message);
  }

  @override
  Future<void> close() async {
    if (!incomingCtrl.isClosed) await incomingCtrl.close();
  }
}
