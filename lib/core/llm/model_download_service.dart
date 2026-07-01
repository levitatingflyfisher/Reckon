// Platform-selected on-device model downloader. The native variant manages
// model files on disk (dart:io + path_provider + dio); the web variant is inert
// (browsers have no on-device model runtime).
//
// Unlike a stub-default conditional, the *native* file is the default here: its
// API (`modelFile` -> dart:io File, injectable dio/storage ctor) isn't
// expressible platform-neutrally, and the analyzer + native build resolve the
// default branch. `dart.library.js_interop` is present only on web, so the web
// build gets the inert variant and never compiles dart:io.
export 'model_download_service_io.dart'
    if (dart.library.js_interop) 'model_download_service_web.dart';
