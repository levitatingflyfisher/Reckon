import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/model_error.dart';

void main() {
  // Regression for the misleading catch-all: any model failure used to say
  // "download it from Settings", sending the user to re-download a model that
  // was already present. The message must depend on whether the file is there.
  test('when the model file is missing, it points the user to Settings to '
      'download', () {
    final msg = modelStartErrorMessage(
        modelDownloaded: false, error: Exception('whatever'));
    final lower = msg.toLowerCase();
    expect(lower, contains('download'));
    expect(lower, contains('settings'));
  });

  test('when the model IS downloaded, it does NOT tell you to re-download — it '
      'surfaces the real error instead', () {
    final msg = modelStartErrorMessage(
      modelDownloaded: true,
      error: StateError('FlutterGemma not initialized'),
    );
    expect(msg.toLowerCase(), isNot(contains('download it from settings')),
        reason: 'a present model must not be blamed on a missing download');
    expect(msg, contains('FlutterGemma not initialized'),
        reason: 'the actual failure should be shown, not hidden');
  });
}
