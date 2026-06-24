import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/sync/party_link.dart';

void main() {
  test('build → parse round-trips relay, id, and key', () {
    const link = PartyJoinLink(
      relayBaseUrl: 'https://relay.example',
      partyId: 'abc123',
      keyString: 'S0VZX0RBVEE',
    );
    final url = link.toUrl();
    expect(url, 'https://relay.example/join/abc123#k=S0VZX0RBVEE');

    final parsed = PartyJoinLink.parse(url)!;
    expect(parsed.relayBaseUrl, 'https://relay.example');
    expect(parsed.partyId, 'abc123');
    expect(parsed.keyString, 'S0VZX0RBVEE');
  });

  test('the key lives in the fragment (never sent to a server)', () {
    final url = const PartyJoinLink(
      relayBaseUrl: 'https://r.example',
      partyId: 'p1',
      keyString: 'KEY',
    ).toUrl();
    // Everything before '#' is what a server would see — it must not contain
    // the key.
    final beforeFragment = url.split('#').first;
    expect(beforeFragment.contains('KEY'), isFalse);
  });

  test('trailing slash on relay base is normalised', () {
    final url = const PartyJoinLink(
      relayBaseUrl: 'https://r.example/',
      partyId: 'p1',
      keyString: 'K',
    ).toUrl();
    expect(url, 'https://r.example/join/p1#k=K');
  });

  test('non-join links and missing key return null', () {
    expect(PartyJoinLink.parse('https://r.example/other/p1#k=K'), isNull);
    expect(PartyJoinLink.parse('https://r.example/join/p1'), isNull);
    expect(PartyJoinLink.parse('not a url at all %%%'), isNull);
  });
}
