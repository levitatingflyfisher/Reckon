import '../../../../core/llm/llm_service.dart';

/// What the export preview starts from: the question text (possibly
/// rewritten) plus the `privacy.redaction` value the request will declare —
/// `local-llm` when the resident model produced the rewrite, `manual` when
/// the user must do it themselves (spec §5 allows either).
class RedactionResult {
  const RedactionResult({
    required this.title,
    required this.background,
    required this.redaction,
  });

  final String title;
  final String background;

  /// `local-llm` | `manual`.
  final String redaction;
}

/// Drafts a de-identified rewrite of a question via the resident model.
///
/// The resolver returns null (or throws) when no model can run here — web,
/// or before a download — and the model itself may return the sentinel; in
/// every failure mode the ORIGINAL text comes back flagged `manual`, because
/// exporting nothing is wrong and exporting silently-unredacted text as
/// "redacted by a model" would be a lie in the wire format. The preview
/// screen is mandatory either way: the model drafts, the user signs off.
class RedactQuestion {
  RedactQuestion(this._resolveLlm);

  final Future<LlmService?> Function() _resolveLlm;

  Future<RedactionResult> call({
    required String title,
    required String background,
  }) async {
    RedactionResult manual() => RedactionResult(
        title: title, background: background, redaction: 'manual');
    try {
      final llm = await _resolveLlm();
      if (llm == null) return manual();
      final r = await llm.redactQuestion(title: title, background: background);
      if (r.isSentinel) return manual();
      return RedactionResult(
          title: r.title, background: r.background, redaction: 'local-llm');
    } catch (_) {
      // Backends promise sentinel-not-throw, but nothing about the export
      // path may crash on a rogue one.
      return manual();
    }
  }
}
