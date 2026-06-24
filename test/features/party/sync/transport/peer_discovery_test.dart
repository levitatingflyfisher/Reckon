import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/transport/peer_discovery.dart';

void main() {
  test('a browser sees a host advertised on the bus, with its lan:// url',
      () async {
    final bus = PeerDiscoveryBus();
    addTearDown(bus.dispose);
    final host = InMemoryPeerDiscovery(bus);
    final joiner = InMemoryPeerDiscovery(bus);

    final seen = joiner.browse().take(1).first;
    await host.advertise(serviceName: 'Dinner', partyId: 'p1', port: 4040);

    final found = await seen;
    expect(found.partyId, 'p1');
    expect(found.port, 4040);
    expect(found.baseUrl, 'lan://127.0.0.1:4040');
  });

  test('a late browser still replays already-advertised hosts', () async {
    final bus = PeerDiscoveryBus();
    addTearDown(bus.dispose);
    await InMemoryPeerDiscovery(bus)
        .advertise(serviceName: 'Trip', partyId: 'p2', port: 5050);

    // Browser created after the advertisement still sees it (mDNS-cache-like).
    final found = await InMemoryPeerDiscovery(bus).browse().take(1).first;
    expect(found.partyId, 'p2');
  });
}
