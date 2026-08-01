// Platform-selected stove backend. The native variant wraps domovoi's
// StoveClient; the web variant is inert. The split exists because domovoi's
// barrel pulls dart:io (stove server, download engine) — and because a
// browser genuinely cannot reach the stove anyway: an https PWA calling a
// LAN http endpoint is blocked as mixed content before CORS even enters.
// `dart.library.js_interop` is present only on web, so the analyzer and the
// native build resolve the default (io) branch.
export 'stove_llm_service_io.dart'
    if (dart.library.js_interop) 'stove_llm_service_web.dart';
