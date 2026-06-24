import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'llm_service.dart';
import 'model_download_service.dart';
import 'model_spec.dart';
import 'private_mode_impl.dart';

/// Singleton [ModelDownloadService] — no async init required.
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});

const _selectedModelKey = 'reckon.selected_model_id';

/// The user's chosen model id, persisted in secure storage. Null until the
/// first selection is made (falls back to [ReckonModelSpec.gemma3_1b]).
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
/// selection; falls back to the default Gemma 1B when no selection exists
/// or the persisted id no longer matches any [ReckonModelSpec.availableModels].
final activeModelSpecProvider = Provider<ReckonModelSpec>((ref) {
  final selected = ref.watch(selectedModelIdProvider).valueOrNull;
  return ReckonModelSpec.byId(selected);
});

/// Resolves to a ready-to-use [LlmService] backed by the on-device model.
///
/// Callers should handle the loading state (model may not yet be downloaded
/// or installed). The provider:
///   1. Verifies the model file exists on disk.
///   2. Installs it into flutter_gemma's runtime.
///   3. Creates an [InferenceModel] and wraps it in [PrivateModeImpl].
///
/// Throws if the model has not been downloaded yet — UI should gate on
/// [ModelDownloadService.isDownloaded] before reading this provider.
final llmServiceProvider = FutureProvider<LlmService>((ref) async {
  // Installing the .task model and creating the native InferenceModel takes
  // several seconds and pins the file on disk. Keep it alive across route
  // changes so navigating Home → Techniques → Home doesn't tear it down.
  ref.keepAlive();

  final spec = ref.watch(activeModelSpecProvider);
  final downloadService = ref.watch(modelDownloadServiceProvider);

  final file = await downloadService.modelFile(spec);
  if (!file.existsSync()) {
    throw StateError(
      'Model "${spec.id}" has not been downloaded yet. '
      'Download it from Settings before using Private mode.',
    );
  }

  // Install the .task file into flutter_gemma's internal storage so
  // the native runtime can load it.
  await FlutterGemma.installModel(modelType: _resolveModelType(spec.modelType))
      .fromFile(file.path)
      .install();

  // Create the inference model.
  final model = await FlutterGemma.getActiveModel(
    maxTokens: 1024,
    preferredBackend: PreferredBackend.gpu,
  );

  ref.onDispose(() async {
    await model.close();
  });

  return PrivateModeImpl(model, spec.id);
});

/// Maps [ReckonModelSpec.modelType] strings onto flutter_gemma's [ModelType]
/// enum. Keeps [ReckonModelSpec] free of flutter_gemma imports so it remains
/// pure Dart and unit-testable.
ModelType _resolveModelType(String name) =>
    ModelType.values.firstWhere((t) => t.name == name,
        orElse: () => ModelType.gemmaIt);
