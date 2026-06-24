import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reckon/core/auth/auth_tier.dart';
import 'package:reckon/core/auth/ghost_auth_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GhostAuthRepositoryImpl', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('getOrCreateAccountId generates UUID and persists on first call', () async {
      final repo = GhostAuthRepositoryImpl();
      final id1 = await repo.getOrCreateAccountId();
      expect(id1, isNotEmpty);
      expect(id1.length, 36);
    });

    test('getOrCreateAccountId returns the same UUID on subsequent calls', () async {
      final repo = GhostAuthRepositoryImpl();
      final id1 = await repo.getOrCreateAccountId();
      final id2 = await repo.getOrCreateAccountId();
      expect(id1, id2);
    });

    test('currentTier is always ghost', () {
      final repo = GhostAuthRepositoryImpl();
      expect(repo.currentTier, AuthTier.ghost);
    });
  });
}
