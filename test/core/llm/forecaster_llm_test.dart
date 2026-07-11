import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/ai_unavailable.dart';
import 'package:reckon/core/llm/forecaster_llm.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';

class _ResidentLlm implements LlmService {
  @override
  String get modelVersion => 'resident-model';
  @override
  Stream<String> conductIntake(IntakeContext ctx) => const Stream.empty();
  @override
  Future<OutsideViewResult> synthesizeOutsideView(
          Case c, ReferenceClassEntry r, UserProfile p) =>
      throw UnimplementedError();
  @override
  Future<MismatchResult> detectRepollSentiment(int lean, String rationale) =>
      throw UnimplementedError();
  @override
  Future<RevealObservation> generateRevealObservation(CaseTimeSeries ts) =>
      throw UnimplementedError();
  @override
  Future<CommunitySeed> generateCommunitySeed(Case c,
          {String? persona, double? temperature}) =>
      throw UnimplementedError();
  @override
  Future<RedactedQuestion> redactQuestion(
          {required String title, required String background}) =>
      throw UnimplementedError();
}

/// Exposes a Ref to the resolver under test.
final _resolverProvider = Provider(
    (ref) => (Forecaster f) => llmServiceForForecaster(ref, f));

Forecaster _forecaster(ForecasterKind kind,
        {Map<String, dynamic> config = const {}}) =>
    Forecaster(
      id: 'f-${kind.name}',
      displayName: kind.name,
      kind: kind,
      config: config,
      createdAt: DateTime(2026, 7, 11),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer container({bool residentAvailable = true}) {
    final c = ProviderContainer(overrides: [
      llmServiceProvider.overrideWith((ref) async {
        if (!residentAvailable) throw const AiUnavailableOnWeb();
        return _ResidentLlm();
      }),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('persona and localModel kinds resolve to the resident service',
      () async {
    final resolve = container().read(_resolverProvider);

    final persona = await resolve(_forecaster(ForecasterKind.persona));
    final local = await resolve(_forecaster(ForecasterKind.localModel));

    expect(persona?.modelVersion, 'resident-model');
    expect(local?.modelVersion, 'resident-model');
  });

  test('persona resolves to null where no resident model exists (web)',
      () async {
    final resolve =
        container(residentAvailable: false).read(_resolverProvider);
    expect(await resolve(_forecaster(ForecasterKind.persona)), isNull);
  });

  test('anthropicByok without a stored key resolves to null', () async {
    final resolve = container().read(_resolverProvider);
    expect(await resolve(_forecaster(ForecasterKind.anthropicByok)), isNull);
  });

  test('anthropicByok with a stored key builds a BYOK service', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'reckon.anthropic_api_key': 'sk-ant-user'});
    final resolve = container().read(_resolverProvider);

    final svc = await resolve(_forecaster(ForecasterKind.anthropicByok));
    expect(svc, isNotNull);
    expect(svc!.modelVersion, 'claude-sonnet-4-6'); // default model

    final custom = await resolve(_forecaster(ForecasterKind.anthropicByok,
        config: {'model': 'claude-haiku-4-5'}));
    expect(custom!.modelVersion, 'claude-haiku-4-5');
  });

  test('openaiCompat builds an HTTP service from base_url + model', () async {
    final resolve = container().read(_resolverProvider);

    final svc = await resolve(_forecaster(ForecasterKind.openaiCompat,
        config: {'base_url': 'http://10.0.0.5:8080', 'model': 'qwen2.5:7b'}));
    expect(svc!.modelVersion, 'qwen2.5:7b');
  });

  test('openaiCompat without a base_url resolves to null', () async {
    final resolve = container().read(_resolverProvider);
    expect(await resolve(_forecaster(ForecasterKind.openaiCompat)), isNull);
  });

  test('openaiCompat with an unparseable base_url resolves to null', () async {
    final resolve = container().read(_resolverProvider);
    expect(
        await resolve(_forecaster(ForecasterKind.openaiCompat,
            config: {'base_url': 'not a url at all ://'})),
        isNull);
  });

  test('bountyBot never resolves — bounty forecasts arrive by import',
      () async {
    final resolve = container().read(_resolverProvider);
    expect(await resolve(_forecaster(ForecasterKind.bountyBot)), isNull);
  });
}
