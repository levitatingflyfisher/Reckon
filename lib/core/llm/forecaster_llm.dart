import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/forecasters/domain/entities/forecaster.dart';
import 'anthropic_key_store.dart';
import 'byok_mode_impl.dart';
import 'llm_providers.dart';
import 'llm_service.dart';
import 'openai_compat_client.dart';
import 'openai_compat_llm_service.dart';

/// Resolves the [LlmService] a forecaster runs on, or `null` when it cannot
/// run here: bounty bots are import-only, BYOK needs a stored key,
/// openaiCompat needs a base URL, and persona/localModel need the resident
/// on-device model (absent on web, or before a download).
///
/// The global [llmServiceProvider] is untouched — intake and the other
/// AI surfaces keep their existing single-backend wiring; the duel resolves
/// per-forecaster so one on-device model and N HTTP backends can coexist.
Future<LlmService?> llmServiceForForecaster(
  Ref ref,
  Forecaster forecaster,
) async {
  switch (forecaster.kind) {
    case ForecasterKind.persona:
    case ForecasterKind.localModel:
      try {
        return await ref.read(llmServiceProvider.future);
      } catch (_) {
        // The builder's two documented construction throws — web
        // (AiUnavailableOnWeb) and model-not-downloaded (StateError) — both
        // mean the same thing to a duel: this forecaster can't run here.
        return null;
      }
    case ForecasterKind.anthropicByok:
      final key = await ref.read(anthropicKeyStoreProvider).getKey();
      if (key == null || key.isEmpty) return null;
      return ByokModeImpl(
        apiKey: key,
        model: forecaster.config['model'] as String? ??
            ByokModeImpl.defaultModel,
      );
    case ForecasterKind.openaiCompat:
      final base = forecaster.config['base_url'] as String?;
      if (base == null || base.isEmpty) return null;
      final baseUrl = Uri.tryParse(base);
      if (baseUrl == null || !baseUrl.hasScheme) return null;
      return OpenAiCompatLlmService(OpenAiCompatClient(
        baseUrl: baseUrl,
        model: forecaster.config['model'] as String? ?? 'default',
      ));
    case ForecasterKind.bountyBot:
      return null;
  }
}
