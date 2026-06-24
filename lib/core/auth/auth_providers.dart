import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_repository.dart';
import 'ghost_auth_repository_impl.dart';

/// The Phase-2 swap point: replace [GhostAuthRepositoryImpl] with the
/// sanctuary_auth-backed implementation when the Token/Named tiers ship.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return GhostAuthRepositoryImpl();
});

const _onboardingKey = 'reckon.onboarding_complete';

/// True once the user has passed through the auth tier screen at least once.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  const storage = FlutterSecureStorage();
  final value = await storage.read(key: _onboardingKey);
  return value == 'true';
});

/// Mark onboarding as done — call this when the user selects a tier.
Future<void> markOnboardingComplete() async {
  const storage = FlutterSecureStorage();
  await storage.write(key: _onboardingKey, value: 'true');
}
