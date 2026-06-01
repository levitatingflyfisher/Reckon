import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'auth_repository.dart';
import 'auth_tier.dart';

class GhostAuthRepositoryImpl implements AuthRepository {
  GhostAuthRepositoryImpl({FlutterSecureStorage? storage, Uuid? uuid})
      : _storage = storage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();

  static const _accountIdKey = 'reckon.account_id';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  @override
  Future<String> getOrCreateAccountId() async {
    final existing = await _storage.read(key: _accountIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = _uuid.v4();
    await _storage.write(key: _accountIdKey, value: fresh);
    return fresh;
  }

  @override
  AuthTier get currentTier => AuthTier.ghost;
}
