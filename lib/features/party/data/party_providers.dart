import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../domain/entities/party.dart';
import '../domain/repositories/party_repository.dart';
import 'local_party_repository.dart';

/// The active [PartyRepository]. Local-first by default: parties live in the
/// on-device database. A future sync-backed implementation can be swapped here
/// without touching the UI or the voting usecases.
final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return LocalPartyRepository(ref.watch(appDatabaseProvider));
});

/// A single party by id (null if it doesn't exist).
final partyProvider = FutureProvider.family<Party?, String>((ref, id) {
  return ref.watch(partyRepositoryProvider).getParty(id);
});

/// The tallied result for a party — an `ApprovalResult` or `RankedResult`.
/// Recomputed whenever invalidated (e.g. after a ballot is submitted).
final partyResultProvider = FutureProvider.family<Object, String>((ref, id) {
  return ref.watch(partyRepositoryProvider).computeResult(id);
});
