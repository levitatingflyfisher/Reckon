import 'dart:async';

/// A party host found on the local network / nearby radio. [address]+[port]
/// give a `lan://` target; [partyId] (from the service's TXT record) lets a
/// joiner match a specific party without contacting the host first.
class DiscoveredHost {
  const DiscoveredHost({
    required this.name,
    required this.address,
    required this.port,
    this.partyId,
  });

  final String name;
  final String address;
  final int port;
  final String? partyId;

  /// The `lan://host:port` base URL for this host.
  String get baseUrl => 'lan://$address:$port';
}

/// Discovery seam for peer-to-peer transports: a host *advertises* a service
/// and joiners *browse* for it. LAN auto-discovery (mDNS) and Nearby both plug
/// in here; the manual QR/link flow is the fallback that needs no discovery.
abstract class PeerDiscovery {
  /// Advertise this device as a host of [partyId] reachable at [port].
  Future<void> advertise({
    required String serviceName,
    required String partyId,
    required int port,
  });

  /// Hosts appearing (and re-appearing) on the network.
  Stream<DiscoveredHost> browse();

  /// Stop advertising and browsing and release resources.
  Future<void> stop();
}

/// In-process discovery for tests and single-device development: anything
/// advertised on a shared [PeerDiscoveryBus] is delivered to every browser.
class InMemoryPeerDiscovery implements PeerDiscovery {
  InMemoryPeerDiscovery(this._bus);
  final PeerDiscoveryBus _bus;
  StreamSubscription<DiscoveredHost>? _sub;

  @override
  Future<void> advertise({
    required String serviceName,
    required String partyId,
    required int port,
  }) async {
    _bus.add(DiscoveredHost(
      name: serviceName,
      address: '127.0.0.1',
      port: port,
      partyId: partyId,
    ));
  }

  @override
  Stream<DiscoveredHost> browse() => _bus.stream;

  @override
  Future<void> stop() async {
    await _sub?.cancel();
  }
}

/// Shared bus backing [InMemoryPeerDiscovery] — the in-process stand-in for the
/// local network.
class PeerDiscoveryBus {
  final _controller = StreamController<DiscoveredHost>.broadcast();
  final _seen = <DiscoveredHost>[];

  void add(DiscoveredHost host) {
    _seen.add(host);
    _controller.add(host);
  }

  /// New hosts, replaying any already advertised so a late browser still sees
  /// them (mirrors how mDNS caches recent services).
  Stream<DiscoveredHost> get stream async* {
    for (final h in _seen) {
      yield h;
    }
    yield* _controller.stream;
  }

  Future<void> dispose() => _controller.close();
}
