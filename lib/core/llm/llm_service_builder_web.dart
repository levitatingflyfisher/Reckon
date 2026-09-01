import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_unavailable.dart';
import 'llm_service.dart';

/// Web: the browser build has no on-device model runtime. Screens read this
/// through `onDeviceModelSupportedProvider` rather than testing `kIsWeb`, so
/// they ask about the capability, not the platform, and cannot offer a model
/// download the build could never use.
const bool hasOnDeviceModelRuntime = false;

/// Web: there is no on-device model and no configured cloud backend, so any
/// attempt to build an LLM service fails with a typed, catchable
/// [AiUnavailableOnWeb]. AI entry points gate on
/// `onDeviceModelSupportedProvider` before reaching this, so in practice it is
/// a backstop rather than a hot path. Nothing here imports flutter_gemma.
Future<LlmService> buildLlmService(Ref ref) async {
  throw const AiUnavailableOnWeb();
}
