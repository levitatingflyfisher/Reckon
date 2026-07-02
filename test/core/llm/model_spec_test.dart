import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/model_spec.dart';

void main() {
  test('trusted litert-community models are ungated (no HF token needed)', () {
    // Verified empirically: an unauthenticated resolve of these URLs returns
    // 302 (redirect to CDN), i.e. no token is required. They were previously
    // mis-flagged requiresToken:true, which put a needless token wall in front
    // of the TRUSTED models while the untrusted personal mirror was tokenless.
    expect(ReckonModelSpec.qwen25_1_5b.requiresToken, isFalse);
    expect(ReckonModelSpec.phi4Mini.requiresToken, isFalse);
    expect(ReckonModelSpec.qwen25_1_5b.downloadUrl, contains('litert-community/'));
    expect(ReckonModelSpec.phi4Mini.downloadUrl, contains('litert-community/'));
  });
}
