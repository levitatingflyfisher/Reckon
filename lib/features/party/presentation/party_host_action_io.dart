import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../data/local_party_repository.dart';
import '../data/party_providers.dart';
import '../sync/party_sync_providers.dart';
import '../sync/transport/lan_host_controller.dart';

/// Native invite action: host the party on the local network and show a QR /
/// link others can join with. Tallies update live as peers vote.
class PartyHostAction extends StatelessWidget {
  const PartyHostAction({super.key, required this.partyId});
  final String partyId;

  @override
  Widget build(BuildContext context) {
    return OHButton(
      label: 'Invite others (same Wi-Fi)',
      style: OHButtonStyle.secondary,
      expanded: true,
      icon: Icons.wifi_tethering,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _LanHostSheet(partyId: partyId),
      ),
    );
  }
}

class _LanHostSheet extends ConsumerStatefulWidget {
  const _LanHostSheet({required this.partyId});
  final String partyId;

  @override
  ConsumerState<_LanHostSheet> createState() => _LanHostSheetState();
}

class _LanHostSheetState extends ConsumerState<_LanHostSheet> {
  LanHostController? _controller;
  Future<HostedLanParty>? _hosting;
  Timer? _poll;
  int _peers = 0;

  @override
  void initState() {
    super.initState();
    final controller = LanHostController(
      ref.read(partyRepositoryProvider) as LocalPartyRepository,
      ref.read(partyKeyStoreProvider),
    );
    _controller = controller;
    _hosting = controller.start(widget.partyId);
    // Poll for peer votes and fold them into the live tally.
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      await controller.syncToLocal();
      if (!mounted) return;
      ref.invalidate(partyResultProvider(widget.partyId));
      ref.invalidate(partyProvider(widget.partyId));
      setState(() => _peers = controller.peerCount);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<HostedLanParty>(
          future: _hosting,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text("Couldn't start hosting: ${snap.error}"),
              );
            }
            final hosted = snap.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Others on this Wi-Fi can scan to join',
                    style: textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Center(
                  child: OHCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: hosted.joinLink,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(hosted.joinLink,
                    style: textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  _peers == 0
                      ? 'Waiting for others to join…'
                      : '$_peers ${_peers == 1 ? 'person' : 'people'} joined',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OHButton(
                  label: 'Share link',
                  icon: Icons.share,
                  expanded: true,
                  onPressed: () => Share.share(hosted.joinLink),
                ),
                const SizedBox(height: 8),
                OHButton(
                  label: 'Stop hosting',
                  style: OHButtonStyle.text,
                  expanded: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
