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

  /// Gemma 4 E2B IT — the default. Google's own build on the trusted
  /// **litert-community** org; an unauthenticated resolve returns 302, so no
  /// HF token (and no account) is needed. This replaces the retired Gemma 3 1B,
  /// which had *no* ungated build on any trusted org and so could only be
  /// pulled from a personal mirror (a supply-chain risk). "E2B" is the ~2B
  /// *effective*-parameter elastic build — noticeably more capable than the old
  /// 1B while staying phone-runnable. The `-web` `.task` is the portable
  /// MediaPipe bundle (the device-specific `.litertlm` builds are NPU variants).
  /// (Size is for the progress UI only — see [approximateSizeBytes].)
  static const gemma4E2B = ReckonModelSpec(
    id: 'gemma-4-e2b-it',
    displayName: 'Gemma 4 (E2B)',
    fileName: 'gemma-4-E2B-it-web.task',
    downloadUrl:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-web.task',
    approximateSizeBytes: 2003000000,
    modelType: 'gemmaIt',
    description: 'Google • ~2B effective • balanced default. '
        'Open weights (litert-community) — no token needed.',
  );

  /// Qwen 2.5 0.5B Instruct — the lightweight tier for storage- or RAM-limited
  /// phones, filling the niche the retired 555 MB Gemma 3 1B used to occupy.
  /// Same trusted litert-community org and same q8-ekv `.task` format as the
  /// 1.5B below (so if that one runs, this one does); Apache-2.0, ungated.
  static const qwen25_0_5b = ReckonModelSpec(
    id: 'qwen-2.5-0.5b-it',
    displayName: 'Qwen 2.5 0.5B',
    fileName: 'qwen25-0-5b-it-q8.task',
    downloadUrl:
        'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    approximateSizeBytes: 546000000,
    modelType: 'qwen',
    description:
        'Alibaba • 0.5B params • smallest + fastest, for low-end devices. '
        'Open weights (litert-community) — no token needed.',
  );

  /// Qwen 2.5 1.5B Instruct — LiteRT .task on the trusted litert-community org.
  /// Open weights: an unauthenticated resolve returns 302 (no HF token needed).
  static const qwen25_1_5b = ReckonModelSpec(
    id: 'qwen-2.5-1.5b-it',
    displayName: 'Qwen 2.5 1.5B',
    fileName: 'qwen25-1-5b-it-int8.task',
    downloadUrl:
        'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    approximateSizeBytes: 1600000000,
    modelType: 'qwen',
    description:
        'Alibaba • 1.5B params • stronger reasoning than the 0.5B models. '
        'Open weights (litert-community) — no token needed.',
  );

  /// Phi-4 Mini Instruct — LiteRT .task on the trusted litert-community org.
  /// Open weights: an unauthenticated resolve returns 302 (no HF token needed).
  static const phi4Mini = ReckonModelSpec(
    id: 'phi-4-mini-it',
    displayName: 'Phi-4 Mini',
    fileName: 'phi4-mini-it-int8.task',
    downloadUrl:
        'https://huggingface.co/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct_multi-prefill-seq_q8_ekv1280.task',
    approximateSizeBytes: 4000000000,
    modelType: 'phi',
    description:
        'Microsoft • 3.8B params • strongest reasoning, heaviest. '
        'Open weights (litert-community) — no token needed. ~4 GB.',
  );

  /// The full roster exposed to the UI, default first.
  static const List<ReckonModelSpec> availableModels = [
    gemma4E2B,
    qwen25_0_5b,
    qwen25_1_5b,
    phi4Mini,
  ];

  /// Look up a spec by [id] with a safe fallback to the default [gemma4E2B]
  /// (used when no selection has been made yet, or a persisted id no longer
  /// matches any [availableModels] entry).
  static ReckonModelSpec byId(String? id) {
    if (id == null) return gemma4E2B;
    for (final s in availableModels) {
      if (s.id == id) return s;
    }
    return gemma4E2B;
  }
}
