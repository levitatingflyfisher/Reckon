import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/features/onboarding/presentation/model_onboarding_screen.dart';

/// Records any attempt to touch model storage; on a build with no runtime
/// there is nothing to check and nothing to fetch.
class _SpyDownloadService extends ModelDownloadService {
  int calls = 0;

  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async {
    calls++;
    return false;
  }

  @override
  Stream<(int, int)> download(ReckonModelSpec spec) {
    calls++;
    return const Stream.empty();
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
      'with no on-device runtime (web), onboarding offers no model download '
      'and lets the user continue', (tester) async {
    final spy = _SpyDownloadService();
    final router = GoRouter(
      initialLocation: '/onboarding/model',
      routes: [
        GoRoute(
            path: '/onboarding/model',
            builder: (_, __) => const ModelOnboardingScreen()),
        GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('HOME REACHED'))),
        GoRoute(
            path: '/onboarding/first-case',
            builder: (_, __) =>
                const Scaffold(body: Text('FIRST CASE REACHED'))),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        onDeviceModelSupportedProvider.overrideWithValue(false),
        modelDownloadServiceProvider.overrideWithValue(spy),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Download'), findsNothing);
    expect(find.textContaining('MB'), findsNothing);
    for (final spec in ReckonModelSpec.availableModels) {
      expect(find.text(spec.displayName), findsNothing);
    }
    expect(spy.calls, 0, reason: 'no storage check or fetch without a runtime');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('HOME REACHED'), findsOneWidget);
  });
}
