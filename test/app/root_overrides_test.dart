// Fleet PWAs share one browser origin, so on web Reckon's recovery words
// must live under Reckon's own key names, never the shared slot every other
// app reads (sanctuary_backup_ui 0.3.0).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/app/root_overrides.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

void main() {
  test('on web the key store is scoped to Reckon', () {
    final container =
        ProviderContainer(overrides: reckonRootOverrides(web: true));
    addTearDown(container.dispose);

    expect(container.read(secureKeyStoreProvider),
        isA<AppScopedSecureKeyStore>());
    expect(container.read(sanctuaryBackupConfigProvider).appId, 'reckon');
    expect(container.read(sanctuaryAppDomainProvider), 'reckon');
  });

  test('on native the platform keychain is used as before', () {
    final container =
        ProviderContainer(overrides: reckonRootOverrides(web: false));
    addTearDown(container.dispose);

    expect(container.read(secureKeyStoreProvider),
        isNot(isA<AppScopedSecureKeyStore>()));
  });
}
