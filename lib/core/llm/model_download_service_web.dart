import 'dart:async';

import 'model_spec.dart';

/// Web build: Reckon has no on-device model runtime in the browser, so there is
/// nothing to download or manage on disk. Every model reports "not downloaded",
/// a download attempt fails cleanly with a typed error, and the HuggingFace
/// token calls are inert. This variant touches no `dart:io`, `path_provider`,
/// or dio file APIs so it is safe in `flutter build web`.
class ModelDownloadService {
  ModelDownloadService();

  Future<bool> isDownloaded(ReckonModelSpec spec) async => false;

  Stream<(int, int)> download(ReckonModelSpec spec) => Stream.error(
        UnsupportedError(
          'On-device models are not available in the web version of Reckon.',
        ),
      );

  Future<void> delete(ReckonModelSpec spec) async {}

  Future<String?> getHfToken() async => null;

  Future<void> setHfToken(String token) async {}

  Future<void> clearHfToken() async {}

  Future<bool> hasHfToken() async => false;
}
