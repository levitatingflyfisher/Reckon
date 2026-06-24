import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nsd/nsd.dart' as nsd;

import 'peer_discovery.dart';

/// mDNS / DNS-SD implementation of [PeerDiscovery] via the `nsd` plugin, so LAN
/// hosts advertise themselves and joiners see them appear with no QR or typing.
/// The party id rides in the service's TXT record, so a joiner can match a
/// specific party. Native only (the plugin uses platform channels); pairs with
/// the LAN socket transport, and falls back to the QR/link flow where mDNS is
/// unavailable.
///
/// Device-only: the Dart surface is analyzer-checked here, but advertise/browse
/// need real multicast on a device/LAN to verify.
class NsdPeerDiscovery implements PeerDiscovery {
  NsdPeerDiscovery({this.serviceType = '_reckonparty._tcp'});

  /// DNS-SD service type all ReckonParty LAN hosts register under.
  final String serviceType;

  static const _partyIdKey = 'pid';

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;
  final _hosts = StreamController<DiscoveredHost>.broadcast();

  @override
  Future<void> advertise({
    required String serviceName,
    required String partyId,
    required int port,
  }) async {
    _registration = await nsd.register(nsd.Service(
      name: serviceName,
      type: serviceType,
      port: port,
      txt: {_partyIdKey: Uint8List.fromList(utf8.encode(partyId))},
    ));
  }

  @override
  Stream<DiscoveredHost> browse() {
    unawaited(_startDiscovery());
    return _hosts.stream;
  }

  Future<void> _startDiscovery() async {
    if (_discovery != null) return;
    final discovery = await nsd.startDiscovery(
      serviceType,
      ipLookupType: nsd.IpLookupType.v4,
    );
    discovery.addServiceListener((service, status) {
      if (status != nsd.ServiceStatus.found) return;
      final host = (service.addresses?.isNotEmpty ?? false)
          ? service.addresses!.first.address
          : service.host;
      final port = service.port;
      if (host == null || port == null) return;
      final pid = service.txt?[_partyIdKey];
      _hosts.add(DiscoveredHost(
        name: service.name ?? 'ReckonParty',
        address: host,
        port: port,
        partyId: pid == null ? null : utf8.decode(pid),
      ));
    });
    _discovery = discovery;
  }

  @override
  Future<void> stop() async {
    final reg = _registration;
    if (reg != null) {
      await nsd.unregister(reg);
      _registration = null;
    }
    final disco = _discovery;
    if (disco != null) {
      await nsd.stopDiscovery(disco);
      _discovery = null;
    }
    if (!_hosts.isClosed) await _hosts.close();
  }
}
