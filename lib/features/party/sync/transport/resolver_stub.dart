import '../party_relay_resolver.dart';

/// Default/web build: cloud (HTTP) relay only. Peer-to-peer transports need
/// `dart:io`, which isn't available on web, so they're added by the native
/// variant (`resolver_io.dart`) via conditional import.
PartyRelayResolver buildPartyRelayResolver() => cloudRelayResolver;
