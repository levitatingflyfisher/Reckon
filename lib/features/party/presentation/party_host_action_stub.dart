import 'package:flutter/widgets.dart';

/// Web (no `dart:io`) build: LAN hosting isn't available in a browser, so the
/// invite action renders nothing. Web participants join via a link instead.
class PartyHostAction extends StatelessWidget {
  const PartyHostAction({super.key, required this.partyId});
  final String partyId;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
