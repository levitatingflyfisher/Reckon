/// Thrown when an AI-backed operation is requested on a build that has no
/// available LLM backend — currently the web PWA, which has no on-device model
/// and no configured cloud key. It is a typed, catchable exception so screens
/// can render a friendly "not available on the web yet" state instead of
/// surfacing a raw error or crashing.
class AiUnavailableOnWeb implements Exception {
  const AiUnavailableOnWeb();

  @override
  String toString() =>
      'AiUnavailableOnWeb: Reckon\'s AI features are not available in the '
      'web version yet.';
}
