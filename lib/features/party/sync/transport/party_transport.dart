import '../party_relay.dart';
import 'channel_relay.dart';
import 'duplex_channel.dart';

/// The transports a party can sync over. `cloud` is the self-hosted HTTP relay;
/// the rest are peer-to-peer and share the channel engine.
enum TransportKind { cloud, lan, nearby, webrtc }

/// A way to establish connectivity for a party and obtain a [PartyRelay] to
/// sync over. [PartySyncService] is transport-agnostic — it only ever sees a
/// [PartyRelay], so adding a transport never touches the crypto, codec, key
/// store, or merge logic.
abstract class PartyTransport {
  TransportKind get kind;

  /// Short user-facing label (e.g. "Same Wi-Fi", "Nearby").
  String get label;

  bool get isPeerToPeer => kind != TransportKind.cloud;
}

/// Self-hosted / cloud HTTP relay. Fully implemented and tested.
class CloudRelayTransport implements PartyTransport {
  const CloudRelayTransport();

  @override
  TransportKind get kind => TransportKind.cloud;

  @override
  String get label => 'Self-hosted relay';

  @override
  bool get isPeerToPeer => false;

  /// A relay client for the relay at [baseUrl].
  PartyRelay relay(String baseUrl) => HttpPartyRelay(baseUrl: baseUrl);
}

/// Base for peer-to-peer transports (LAN, Nearby, WebRTC). They differ only in
/// how a [DuplexChannel] to a peer is established; once one exists, the shared
/// engine takes over — a joining peer wraps it as a [ChannelPartyRelay] and the
/// host attaches a [ChannelRelayHost]. Subclasses implement the backend-specific
/// discovery/connection (the on-device step); everything above the channel is
/// already built and tested.
abstract class ChannelTransport implements PartyTransport {
  const ChannelTransport();

  @override
  bool get isPeerToPeer => true;

  /// Joiner side: speak the relay protocol to the host over [channel].
  ChannelPartyRelay relayOver(DuplexChannel channel) =>
      ChannelPartyRelay(channel);

  /// Host side: answer peers over [channel] (one per connected peer).
  ChannelRelayHost hostOver(DuplexChannel channel) => ChannelRelayHost(channel);
}

/// Same-Wi-Fi peer-to-peer. Channel backend: a framed TCP/WebSocket socket;
/// discovery via mDNS (or QR / manual host IP). The socket + mDNS adapters use
/// `dart:io` and are mobile-only — wired up in the on-device step.
class LanTransport extends ChannelTransport {
  const LanTransport();
  @override
  TransportKind get kind => TransportKind.lan;
  @override
  String get label => 'Same Wi-Fi';
}

/// Bluetooth / Wi-Fi Direct mesh via Android Nearby Connections (iOS
/// Multipeer). Channel backend wraps the plugin's payload stream. No shared
/// network needed; Android-first, device-only — wired up in the on-device step.
class NearbyTransport extends ChannelTransport {
  const NearbyTransport();
  @override
  TransportKind get kind => TransportKind.nearby;
  @override
  String get label => 'Nearby';
}

/// Internet peer-to-peer via WebRTC data channels. Scaffolded for later: needs
/// a signaling rendezvous + STUN, and a TURN relay fallback. Channel backend
/// wraps an `RTCDataChannel`.
class WebRtcTransport extends ChannelTransport {
  const WebRtcTransport();
  @override
  TransportKind get kind => TransportKind.webrtc;
  @override
  String get label => 'Internet (WebRTC)';
}
