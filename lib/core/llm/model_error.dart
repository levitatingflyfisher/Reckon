/// User-facing message for an on-device-model start failure.
///
/// Only points the user to Settings to *download* when the model file is
/// genuinely missing. When the model is present but failed to start (e.g. a
/// plugin init bug, an incompatible build, low memory), it surfaces the real
/// error instead of misleadingly telling them to re-download a model they
/// already have.
String modelStartErrorMessage({
  required bool modelDownloaded,
  required Object error,
}) {
  if (!modelDownloaded) {
    return "The on-device model isn't downloaded yet. "
        'Download it from Settings before starting a case.';
  }
  return "The model is downloaded but couldn't start.\n\n($error)";
}
