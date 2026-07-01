import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'llm_providers.dart';
import 'llm_service.dart';
import 'private_mode_impl.dart';

/// Native: resolve the selected [ReckonModelSpec], verify its file is on disk,
/// install it into flutter_gemma's runtime, and wrap the resulting
/// [InferenceModel] in [PrivateModeImpl].
///
/// Installing the .task model and creating the native InferenceModel takes
/// several seconds and pins the file on disk, so the caller's provider is kept
/// alive across route changes (Home → Techniques → Home) rather than torn down.
///
/// Throws if the model has not been downloaded yet — UI gates on
/// [ModelDownloadService.isDownloaded] before triggering this.
Future<LlmService> buildLlmService(Ref ref) async {
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

  // Create the inference model. maxTokens caps the whole context (system
  // prompt + conversation + reply). 1024 was far too small for a multi-turn
  // intake: the system prompt plus a couple of exchanges overran it, and the
  // model would return empty/garbled output ("stops responding after a turn
  // or two"). 4096 gives the small model room for the full interview.
  final model = await FlutterGemma.getActiveModel(
    maxTokens: 4096,
    preferredBackend: PreferredBackend.gpu,
  );

  ref.onDispose(() async {
    await model.close();
  });

  return PrivateModeImpl(model, spec.id);
}

/// Maps [ReckonModelSpec.modelType] strings onto flutter_gemma's [ModelType]
/// enum. Keeps [ReckonModelSpec] free of flutter_gemma imports so it remains
/// pure Dart and unit-testable.
ModelType _resolveModelType(String name) =>
    ModelType.values.firstWhere((t) => t.name == name,
        orElse: () => ModelType.gemmaIt);
