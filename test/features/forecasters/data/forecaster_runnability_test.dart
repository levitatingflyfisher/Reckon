import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/core/database/database_providers.dart';
import 'package:reckon/core/llm/anthropic_key_store.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/features/forecasters/data/forecaster_providers.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';

class _FakeDownloadService extends ModelDownloadService {
  _FakeDownloadService(this._downloaded);
  final Set<String> _downloaded;
  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async =>
      _downloaded.contains(spec.id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  ProviderContainer container({Set<String> downloaded = const {}}) {
    final c = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      selectedModelIdProvider.overrideWith((ref) async => null),
      modelDownloadServiceProvider
          .overrideWithValue(_FakeDownloadService(downloaded)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('default personas are runnable once the resident model is downloaded',
      () async {
    final defaultId = ReckonModelSpec.byId(null).id;
    final runnable = await container(downloaded: {defaultId})
        .read(runnableForecastersProvider.future);

    expect(runnable, hasLength(2));
    expect(runnable.every((f) => f.kind == ForecasterKind.persona), isTrue);
  });

  test('personas are NOT runnable before the model is downloaded', () async {
    final runnable =
        await container().read(runnableForecastersProvider.future);
    expect(runnable, isEmpty);
  });

  test('a BYOK forecaster is runnable only when a key is stored', () async {
    final c = container();
    final repo = c.read(forecasterRepositoryProvider);
    await repo.all(); // seed defaults
    await repo.upsert(Forecaster(
      id: 'claude',
      displayName: 'Claude',
      kind: ForecasterKind.anthropicByok,
      createdAt: DateTime(2026, 7, 11),
    ));

    expect(await c.read(runnableForecastersProvider.future), isEmpty);

    FlutterSecureStorage.setMockInitialValues(
        {'reckon.anthropic_api_key': 'sk-ant-user'});
    // Key mutations invalidate hasAnthropicKeyProvider (see its doc comment);
    // runnability recomputes through the watch chain.
    c.invalidate(hasAnthropicKeyProvider);
    final runnable = await c.read(runnableForecastersProvider.future);
    expect(runnable.map((f) => f.id), ['claude']);
  });

  test('an openaiCompat forecaster is runnable when it has a base_url',
      () async {
    final c = container();
    final repo = c.read(forecasterRepositoryProvider);
    await repo.all();
    await repo.upsert(Forecaster(
      id: 'llamafile',
      displayName: 'LAN llamafile',
      kind: ForecasterKind.openaiCompat,
      config: const {'base_url': 'http://192.168.1.20:8080'},
      createdAt: DateTime(2026, 7, 11),
    ));

    final runnable = await c.read(runnableForecastersProvider.future);
    expect(runnable.map((f) => f.id), ['llamafile']);
  });

  test('disabled and bounty forecasters are never runnable', () async {
    final c = container();
    final repo = c.read(forecasterRepositoryProvider);
    await repo.all();
    await repo.upsert(Forecaster(
      id: 'bounty:bob',
      displayName: 'bob',
      kind: ForecasterKind.bountyBot,
      createdAt: DateTime(2026, 7, 11),
    ));
    await repo.upsert(Forecaster(
      id: 'off',
      displayName: 'Off endpoint',
      kind: ForecasterKind.openaiCompat,
      config: const {'base_url': 'http://192.168.1.20:8080'},
      enabled: false,
      createdAt: DateTime(2026, 7, 11),
    ));

    expect(await c.read(runnableForecastersProvider.future), isEmpty);
  });
}
