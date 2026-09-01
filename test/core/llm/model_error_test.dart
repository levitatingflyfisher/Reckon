import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
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

  test('when the model IS downloaded, it does not blame a missing download, '
      'and the raw error stays in the log, not the transcript', () {
    final msg = modelStartErrorMessage(
      modelDownloaded: true,
      error: StateError('FlutterGemma not initialized'),
    );
    expect(msg.toLowerCase(), isNot(contains('download it from settings')),
        reason: 'a present model must not be blamed on a missing download');
    expect(msg, contains("couldn’t start"));
    // Fleet error ruling: never print the exception on screen.
    expect(msg, isNot(contains('FlutterGemma not initialized')));
    expect(msg, isNot(contains('StateError')));
  });

  group('modelDownloadErrorMessage', () {
    test('a missing token keeps its own sentence (it is ours, and it says '
        'what to do)', () {
      final msg = modelDownloadErrorMessage(StateError(
          'This model needs a HuggingFace token. Add one in Settings.'));
      expect(msg, contains('token'));
      expect(msg, isNot(contains('StateError')));
    });

    test('a network failure reads as a network failure', () {
      final msg = modelDownloadErrorMessage(DioException(
        requestOptions: RequestOptions(path: 'https://example.invalid/m'),
        type: DioExceptionType.connectionError,
        message: 'SocketException: Failed host lookup',
      ));
      expect(msg, OhErrorMessages.network);
    });

    test('a refused download names the token without the status dump', () {
      final req = RequestOptions(path: 'https://example.invalid/m');
      final msg = modelDownloadErrorMessage(DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: req, statusCode: 401),
      ));
      expect(msg.toLowerCase(), contains('token'));
      expect(msg, isNot(contains('401')));
      expect(msg, isNot(contains('DioException')));
    });

    test('anything else gets the plain generic sentence', () {
      final msg = modelDownloadErrorMessage(Exception('disk on fire'));
      expect(msg, isNot(contains('disk on fire')));
      expect(msg, isNotEmpty);
    });
  });
}
