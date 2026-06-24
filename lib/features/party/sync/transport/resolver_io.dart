import '../party_relay_resolver.dart';
import 'lan_relay_resolver.dart';

/// Native (mobile/desktop) build: LAN (`lan://`) peer-to-peer plus cloud.
PartyRelayResolver buildPartyRelayResolver() => lanAndCloudResolver();
