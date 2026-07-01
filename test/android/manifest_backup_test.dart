import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The decision journal (reckon.sqlite) is plaintext on disk. Android Auto
/// Backup defaults to ON, which would silently upload it to the user's Google
/// account — off-thesis for a local-first app. The sanctioned backup path is
/// the encrypted .ohbk export, so the manifest must opt out of platform
/// backup/extraction entirely.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  test('manifest disables Android Auto Backup', () {
    final xml = manifest.readAsStringSync();
    expect(xml, contains('android:allowBackup="false"'),
        reason: 'plaintext reckon.sqlite must not auto-upload to Google');
  });

  test('manifest wires dataExtractionRules (Android 12+) and '
      'fullBackupContent (pre-12)', () {
    final xml = manifest.readAsStringSync();
    expect(xml,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    expect(xml, contains('android:fullBackupContent="@xml/backup_rules"'));
  });

  test('data_extraction_rules disables cloud-backup and device-transfer', () {
    final rules =
        File('android/app/src/main/res/xml/data_extraction_rules.xml');
    expect(rules.existsSync(), isTrue);
    final xml = rules.readAsStringSync();
    expect(xml, contains('<cloud-backup'));
    expect(xml, contains('<device-transfer'));
    expect(xml, contains('domain="root"'));
  });

  test('backup_rules excludes everything for pre-Android-12 Auto Backup', () {
    final rules = File('android/app/src/main/res/xml/backup_rules.xml');
    expect(rules.existsSync(), isTrue);
    final xml = rules.readAsStringSync();
    expect(xml, contains('<exclude domain="root" path="."/>'));
  });
}
