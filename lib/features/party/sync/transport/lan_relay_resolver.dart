/// Mobile/desktop resolver that adds LAN (`lan://host:port`) on top of the
/// web-safe cloud resolver. Lives apart from `party_relay_resolver.dart` because
/// it reaches `dart:io` (via [connectToLanHost]) and must not be imported by
/// web-reachable code.
library;

import '../party_relay_resolver.dart';
import 'channel_relay.dart';
import 'lan_socket_channel.dart';

/// A [PartyRelayResolver] handling `lan://host:port` by opening a TCP channel to
/// the host, and delegating everything else to [cloudRelayResolver].
PartyRelayResolver lanAndCloudResolver() {
  return (baseUrl) async {
    final uri = Uri.tryParse(baseUrl);
    if (uri != null && uri.scheme == 'lan') {
      final channel = await connectToLanHost(uri.host, uri.port);
      return ChannelPartyRelay(channel);
    }
    return cloudRelayResolver(baseUrl);
  };
}
