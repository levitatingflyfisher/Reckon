import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_unavailable.dart';
import 'llm_service.dart';

/// Web: there is no on-device model and no configured cloud backend, so any
/// attempt to build an LLM service fails with a typed, catchable
/// [AiUnavailableOnWeb]. AI entry points gate on `kIsWeb` before reaching this,
/// so in practice it is a backstop rather than a hot path. Nothing here imports
/// flutter_gemma.
Future<LlmService> buildLlmService(Ref ref) async {
  throw const AiUnavailableOnWeb();
}
