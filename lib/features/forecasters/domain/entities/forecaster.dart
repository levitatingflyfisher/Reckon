/// How a [Forecaster]'s forecasts are produced.
enum ForecasterKind {
  /// A prompt persona over the resident on-device model — a stance sentence
  /// in [Forecaster.config]`['persona']`, no extra runtime.
  persona,

  /// The resident on-device model itself, un-personified.
  localModel,

  /// The user's own Anthropic API key (key lives in secure storage, never in
  /// [Forecaster.config]).
  anthropicByok,

  /// Any OpenAI-compatible chat endpoint (llamafile, Ollama, vLLM…) —
  /// `config['base_url']` + `config['model']`.
  openaiCompat,

  /// The household stove: a home server reached over domovoi's encrypted
  /// stove protocol — `config['host']` + optional `config['port']`; the
  /// household phrase lives in secure storage, never in config.
  stove,

  /// An outside bot whose responses arrive via reckonBounty import. Never
  /// called directly; it exists so imported forecasts earn a track record.
  bountyBot,
}

/// A forecast participant: anyone who may "duel" the user on a decision and
/// earn a track record against its resolutions. Identity + non-secret config
/// only — predictions live in ModelPredictions, secrets in secure storage.
///
/// Immutable, hand-written (house style: no codegen for domain entities).
class Forecaster {
  const Forecaster({
    required this.id,
    required this.displayName,
    required this.kind,
    this.config = const {},
    this.enabled = true,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final ForecasterKind kind;

  /// Kind-specific, non-secret configuration (persona stance, base_url,
  /// model name…). Persisted as JSON.
  final Map<String, dynamic> config;

  /// Disabled forecasters keep their history but sit out future duels.
  final bool enabled;

  final DateTime createdAt;

  Forecaster copyWith({
    String? displayName,
    Map<String, dynamic>? config,
    bool? enabled,
  }) =>
      Forecaster(
        id: id,
        displayName: displayName ?? this.displayName,
        kind: kind,
        config: config ?? this.config,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt,
      );
}
