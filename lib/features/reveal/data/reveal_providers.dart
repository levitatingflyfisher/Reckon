import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/llm/llm_providers.dart';
import '../../predictions/data/prediction_providers.dart';
import '../domain/usecases/generate_reveal.dart';

final generateRevealProvider = FutureProvider<GenerateReveal>((ref) async {
  final llm = await ref.watch(llmServiceProvider.future);
  return GenerateReveal(llm, ref.watch(predictionRepositoryProvider));
});
