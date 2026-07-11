import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'llm_service.dart';
import 'llm_service_builder.dart';
import 'model_download_service.dart';
import 'model_spec.dart';

/// Singleton [ModelDownloadService] — no async init required.
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});

const _selectedModelKey = 'reckon.selected_model_id';

/// The user's chosen model id, persisted in secure storage. Null until the
/// first selection is made (falls back to the default [ReckonModelSpec.qwen25_1_5b]).
final selectedModelIdProvider = FutureProvider<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return storage.read(key: _selectedModelKey);
});

/// Persist [id] as the active model. After writing, the caller should
/// invalidate [selectedModelIdProvider] and [llmServiceProvider] so the
/// new model is loaded.
Future<void> persistSelectedModelId(String id) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: _selectedModelKey, value: id);
}

/// Which model the LLM service should load. Derived from the persisted
/// selection; falls back to the default Qwen 2.5 1.5B when no selection exists
/// or the persisted id no longer matches any [ReckonModelSpec.availableModels].
final activeModelSpecProvider = Provider<ReckonModelSpec>((ref) {
  final selected = ref.watch(selectedModelIdProvider).valueOrNull;
  return ReckonModelSpec.byId(selected);
});

/// Resolves to a ready-to-use [LlmService].
///
/// The concrete backend is platform-selected by [buildLlmService]:
///   * native — loads the selected on-device model into flutter_gemma and wraps
///     it in `PrivateModeImpl`. Throws if the model has not been downloaded yet,
///     so UI should gate on [ModelDownloadService.isDownloaded] first.
///   * web — throws a catchable `AiUnavailableOnWeb`, since the browser build
///     has no model runtime. AI entry points gate on `kIsWeb` before reading
///     this, so a web user sees a friendly disabled state, never a crash.
final llmServiceProvider =
    FutureProvider<LlmService>((ref) => buildLlmService(ref));
