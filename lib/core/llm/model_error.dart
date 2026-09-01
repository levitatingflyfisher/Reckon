import 'package:dio/dio.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// User-facing message for an on-device-model start failure.
///
/// Only points the user to Settings to *download* when the model file is
/// genuinely missing. When the model is present but failed to start (e.g. a
/// plugin init bug, an incompatible build, low memory), it says so, rather
/// than misleadingly telling them to re-download a model they already have.
/// The exception itself is never part of the sentence (fleet error ruling);
/// callers log it.
String modelStartErrorMessage({
  required bool modelDownloaded,
  required Object error,
}) {
  if (!modelDownloaded) {
    return "The on-device model isn’t downloaded yet. "
        'Download it from Settings before starting a decision.';
  }
  return "The model is downloaded but couldn’t start. Closing other apps "
      'to free memory and trying again often helps.';
}

/// User-facing sentence for a failed model download. Never the exception
/// text: the download service's own missing-token [StateError] is a sentence
/// we wrote and says what to do, so it is kept; a network failure reads as
/// one; a refused download (401/403) points at the token; anything else is
/// the fleet's plain sentence. Callers log [error].
String modelDownloadErrorMessage(Object error) {
  if (error is StateError && error.message.contains('token')) {
    return error.message;
  }
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'The model host refused the download. If this model needs a '
          'HuggingFace token, check the one in Settings.';
    }
    if (error.type == DioExceptionType.badResponse) {
      return "The model host couldn’t send the file right now. Try again "
          'later; what has downloaded so far is kept.';
    }
    return OhErrorMessages.network;
  }
  return ohFriendlyErrorMessage(error);
}
