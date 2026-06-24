import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_party_repository.dart';
import '../data/party_providers.dart';
import 'party_key_store.dart';
import 'party_relay_resolver.dart';
import 'party_sync_service.dart';
// The resolver is platform-selected at compile time: web gets cloud-only
// (no dart:io), native gets LAN + cloud.
import 'transport/resolver_stub.dart'
    if (dart.library.io) 'transport/resolver_io.dart';

/// Persistent, secure store for per-party sync keys (production).
final partyKeyStoreProvider =
    Provider<PartyKeyStore>((_) => SecurePartyKeyStore());

/// Resolves a relay base URL to a connected relay, by transport scheme.
final partyRelayResolverProvider =
    Provider<PartyRelayResolver>((_) => buildPartyRelayResolver());

/// The optional remote-participation layer over the local-first store. Disposed
/// with the provider scope so any open transport sockets are released.
final partySyncServiceProvider = Provider<PartySyncService>((ref) {
  // partyRepositoryProvider is always a LocalPartyRepository; the sync service
  // needs the concrete type for its local-store operations.
  final local = ref.watch(partyRepositoryProvider) as LocalPartyRepository;
  final service = PartySyncService(
    local: local,
    keys: ref.watch(partyKeyStoreProvider),
    relayFor: ref.watch(partyRelayResolverProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Whether a party has been shared/joined on this device (has a sync key).
final partyIsSyncedProvider = FutureProvider.family<bool, String>((ref, id) {
  return ref.watch(partySyncServiceProvider).isSynced(id);
});
