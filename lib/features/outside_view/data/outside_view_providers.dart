import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/llm/llm_providers.dart';
import '../../predictions/data/prediction_providers.dart';
import '../domain/entities/outside_view.dart';
import '../domain/repositories/outside_view_repository.dart';
import '../domain/usecases/get_outside_view.dart';
import 'outside_view_repository_impl.dart';

final outsideViewRepositoryProvider =
    Provider<OutsideViewRepository>((ref) {
  return OutsideViewRepositoryImpl(ref.watch(appDatabaseProvider));
});

final getOutsideViewProvider = FutureProvider((ref) async {
  final llm = await ref.watch(llmServiceProvider.future);
  return GetOutsideView(
    ref.watch(outsideViewRepositoryProvider),
    llm,
    ref.watch(predictionRepositoryProvider),
  );
});

final outsideViewForCaseProvider =
    FutureProvider.family<OutsideView?, String>((ref, caseId) async {
  return ref.watch(outsideViewRepositoryProvider).getForCase(caseId);
});
