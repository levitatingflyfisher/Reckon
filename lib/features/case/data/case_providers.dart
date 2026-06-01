import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_providers.dart';
import '../domain/entities/case.dart';
import '../domain/entities/poll.dart';
import '../domain/repositories/case_repository.dart';
import '../domain/repositories/poll_repository.dart';
import '../domain/usecases/add_poll.dart';
import '../domain/usecases/create_case.dart';
import '../domain/usecases/mark_decided.dart';
import 'case_repository_impl.dart';
import 'poll_repository_impl.dart';

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  return CaseRepositoryImpl(ref.watch(appDatabaseProvider));
});

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepositoryImpl(ref.watch(appDatabaseProvider));
});

final createCaseProvider =
    Provider((ref) => CreateCase(ref.watch(caseRepositoryProvider)));

final addPollProvider =
    Provider((ref) => AddPoll(ref.watch(pollRepositoryProvider)));

final markDecidedProvider =
    Provider((ref) => MarkDecided(ref.watch(caseRepositoryProvider)));

final openCasesStreamProvider = StreamProvider<List<Case>>((ref) {
  return ref.watch(caseRepositoryProvider).watchActive();
});

final caseByIdProvider =
    FutureProvider.family<Case?, String>((ref, id) async {
  return ref.watch(caseRepositoryProvider).getById(id);
});

final pollsForCaseProvider =
    FutureProvider.family<List<Poll>, String>((ref, caseId) async {
  return ref.watch(pollRepositoryProvider).getByCaseId(caseId);
});
