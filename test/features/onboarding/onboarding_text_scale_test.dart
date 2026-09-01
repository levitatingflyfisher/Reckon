import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';
import 'package:reckon/features/onboarding/presentation/auth_tier_screen.dart';
import 'package:reckon/features/onboarding/presentation/first_case_prompt_screen.dart';
import 'package:reckon/features/onboarding/presentation/model_onboarding_screen.dart';

/// Nothing on disk; a download "completes" at once, so the primary button on
/// the model step can be pressed for real without touching the network.
class _InstantDownloadService extends ModelDownloadService {
  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async => false;

  @override
  Stream<(int, int)> download(ReckonModelSpec spec) =>
      Stream.value((1, 1));
}

const _wakelockChannels = [
  'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
  'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.isEnabled',
];

/// A 360x640 dp phone with Android's font size one notch above default
/// (textScaler 1.3) is an ordinary configuration. Every onboarding step must
/// be finishable there: no overflow, and each step's primary action on screen
/// and hittable without the user having to find it.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _wakelockChannels) {
      messenger.setMockMessageHandler(name, (_) async {
        return const StandardMessageCodec().encodeMessage(<Object?>[false]);
      });
    }
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _wakelockChannels) {
      messenger.setMockMessageHandler(name, null);
    }
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: '/onboarding/auth',
      routes: [
        GoRoute(
            path: '/onboarding/auth',
            builder: (_, __) => const AuthTierScreen()),
        GoRoute(
            path: '/onboarding/model',
            builder: (_, __) => const ModelOnboardingScreen()),
        GoRoute(
            path: '/onboarding/first-case',
            builder: (_, __) => const FirstCasePromptScreen()),
        GoRoute(
            path: '/intake',
            builder: (_, __) => const Scaffold(body: Text('INTAKE REACHED'))),
        GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('HOME REACHED'))),
      ],
    );
    return ProviderScope(
      overrides: [
        selectedModelIdProvider.overrideWith((ref) async => null),
        modelDownloadServiceProvider
            .overrideWithValue(_InstantDownloadService()),
      ],
      child: MaterialApp.router(
        theme: ReckonTheme.light(),
        routerConfig: router,
      ),
    );
  }

  /// The button must sit fully inside the viewport as laid out, with no
  /// scrolling, and its centre must be the widget a tap would reach.
  void expectReachable(WidgetTester tester, Finder button) {
    expect(button, findsOneWidget);
    final rect = tester.getRect(button);
    expect(rect.top, greaterThanOrEqualTo(0), reason: 'button above viewport');
    expect(rect.bottom, lessThanOrEqualTo(640),
        reason: 'primary action is clipped off the bottom of a 640 dp screen');
    final hits = tester.hitTestOnBinding(rect.center);
    final target = tester.renderObject(button);
    expect(hits.path.any((e) => e.target == target), isTrue,
        reason: 'something else owns the tap at the button centre');
    // OHButton ellipsizes rather than overflowing, which an overflow check
    // cannot see: the label must be legible in full, not "Continue wi…".
    final label = tester.renderObject<RenderParagraph>(find
        .descendant(of: button, matching: find.byType(RichText))
        .first);
    expect(label.didExceedMaxLines, isFalse,
        reason: 'primary label is truncated: ${label.text.toPlainText()}');
  }

  testWidgets('every onboarding step is finishable at 360x640 dp, text 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Step 1: privacy tier.
    final cont = find.widgetWithText(ElevatedButton, 'Continue privately');
    expectReachable(tester, cont);
    await tester.tap(cont);
    await tester.pumpAndSettle();

    // Step 2: model download (the primary action is the Download button).
    final download = find.byType(ElevatedButton);
    expectReachable(tester, download);
    await tester.tap(download);
    await tester.pumpAndSettle();

    // Step 3: first-case prompt.
    final open = find.widgetWithText(ElevatedButton, 'Start a decision');
    expectReachable(tester, open);
    await tester.tap(open);
    await tester.pumpAndSettle();

    expect(find.text('INTAKE REACHED'), findsOneWidget);
  });
}
