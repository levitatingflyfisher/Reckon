// One-time flutter_gemma runtime initialization, platform-selected so the web
// build never imports flutter_gemma. `dart.library.io` is present natively and
// absent on the web; both variants expose `Future<void> initGemma()`.
export 'gemma_init_web.dart' if (dart.library.io) 'gemma_init_native.dart';
