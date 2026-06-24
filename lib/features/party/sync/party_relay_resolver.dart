import 'party_relay.dart';

/// Resolves a relay base URL to a connected [PartyRelay]. Async because some
/// transports (LAN sockets, WebRTC) must connect before they can talk. The
/// scheme selects the transport, so `PartySyncService` stays transport-agnostic.
typedef PartyRelayResolver = Future<PartyRelay> Function(String baseUrl);

/// Web-safe resolver for the cloud / self-hosted HTTP relay (`http(s)://`).
/// Peer-to-peer schemes are added by composing on top of this (see the
/// mobile-only `lanAndCloudResolver`).
Future<PartyRelay> cloudRelayResolver(String baseUrl) async {
  final scheme = Uri.tryParse(baseUrl)?.scheme;
  if (scheme == 'http' || scheme == 'https') {
    return HttpPartyRelay(baseUrl: baseUrl);
  }
  throw ArgumentError('Unsupported relay URL: $baseUrl');
}
