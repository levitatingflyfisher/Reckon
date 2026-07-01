// Platform-selected LLM service factory. The native variant loads the selected
// on-device model into flutter_gemma; the web variant throws a catchable
// [AiUnavailableOnWeb] because the browser build has no model runtime. Keeping
// the flutter_gemma-dependent construction behind `dart.library.io` means a web
// build never references flutter_gemma. Both variants expose
// `Future<LlmService> buildLlmService(Ref ref)`.
export 'llm_service_builder_web.dart'
    if (dart.library.io) 'llm_service_builder_native.dart';
