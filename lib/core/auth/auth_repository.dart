import 'auth_tier.dart';

abstract class AuthRepository {
  Future<String> getOrCreateAccountId();
  AuthTier get currentTier;
}
