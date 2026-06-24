import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the system browser, showing a SnackBar if it can't be
/// handled. Shared by every citation surface so link behaviour is consistent.
/// [launcher] is injectable for widget tests.
Future<void> openExternalUrl(
  BuildContext context,
  String url, {
  Future<bool> Function(Uri uri)? launcher,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final launch =
      launcher ?? (u) => launchUrl(u, mode: LaunchMode.externalApplication);
  bool ok;
  try {
    ok = await launch(Uri.parse(url));
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }
}
