/// Describes a downloadable on-device LLM model.
///
/// Multi-model by design. Add new entries to [availableModels] and they
/// appear in Settings automatically. [modelType] is a string so this class
/// stays free of flutter_gemma imports (pure Dart, testable).
class ReckonModelSpec {
  const ReckonModelSpec({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.downloadUrl,
    required this.approximateSizeBytes,
    required this.modelType,
    this.requiresToken = false,
    this.description = '',
  });

  /// Stable machine-readable identifier — also the key used to persist
  /// the user's selection across launches.
  final String id;

  /// Human-readable name shown in Settings.
  final String displayName;

  /// The file name to use in the app documents directory. Distinct per
  /// spec so multiple downloaded models can coexist on disk.
  final String fileName;

  /// Where to download the model from.
  final String downloadUrl;

  /// Approximate file size in bytes — used for progress UI, not validation.
  final int approximateSizeBytes;

  /// Maps to `ModelType` in flutter_gemma. Stored as a string so this file
  /// has no flutter_gemma import.
  final String modelType;

  /// Whether the download URL requires a HuggingFace Authorization header.
  /// Ungated mirrors should leave this `false` so Settings doesn't show
  /// token UI for them.
  final bool requiresToken;

  /// One-line description shown in Settings to help the user pick.
  final String description;

  /// Gemma 3 1B IT — int4 quantised, ~555 MB. Ungated community mirror.
  /// (Size is for the progress UI only — see [approximateSizeBytes].)
  static const gemma3_1b = ReckonModelSpec(
    id: 'gemma-3-1b-it',
    displayName: 'Gemma 3 1B',
    fileName: 'gemma3-1b-it-int4.task',
    downloadUrl:
        'https://huggingface.co/MiCkSoftware/Gemma3-1B-IT-LiteRT/resolve/main/gemma3-1b-it-int4.task',
    approximateSizeBytes: 555000000,
    modelType: 'gemmaIt',
    description: 'Google • 1B params • fast, low memory. Default.',
  );

  /// Qwen 2.5 1.5B Instruct — LiteRT .task. Gated; requires HF token.
  static const qwen25_1_5b = ReckonModelSpec(
    id: 'qwen-2.5-1.5b-it',
    displayName: 'Qwen 2.5 1.5B',
    fileName: 'qwen25-1-5b-it-int8.task',
    downloadUrl:
        'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    approximateSizeBytes: 1600000000,
    modelType: 'qwen',
    requiresToken: true,
    description:
        'Alibaba • 1.5B params • often stronger reasoning than Gemma 1B. '
        'Gated on HuggingFace — requires a token.',
  );

  /// Phi-4 Mini Instruct — LiteRT .task. Gated; larger file, needs HF token.
  static const phi4Mini = ReckonModelSpec(
    id: 'phi-4-mini-it',
    displayName: 'Phi-4 Mini',
    fileName: 'phi4-mini-it-int8.task',
    downloadUrl:
        'https://huggingface.co/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct_multi-prefill-seq_q8_ekv1280.task',
    approximateSizeBytes: 4000000000,
    modelType: 'phi',
    requiresToken: true,
    description:
        'Microsoft • 3.8B params • strongest reasoning, heaviest. '
        'Gated on HuggingFace — requires a token. ~4 GB.',
  );

  /// The full roster exposed to the UI.
  static const List<ReckonModelSpec> availableModels = [
    gemma3_1b,
    qwen25_1_5b,
    phi4Mini,
  ];

  /// Look up a spec by [id] with a safe fallback to [gemma3_1b].
  static ReckonModelSpec byId(String? id) {
    if (id == null) return gemma3_1b;
    for (final s in availableModels) {
      if (s.id == id) return s;
    }
    return gemma3_1b;
  }
}
