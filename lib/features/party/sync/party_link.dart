/// A parsed ReckonParty join link: which relay, which party, and the decryption
/// key. The key lives in the URL **fragment** (`#k=…`) so it never reaches the
/// relay (or any server) — browsers don't transmit fragments.
class PartyJoinLink {
  const PartyJoinLink({
    required this.relayBaseUrl,
    required this.partyId,
    required this.keyString,
  });

  final String relayBaseUrl;
  final String partyId;
  final String keyString;

  /// Build a shareable link, e.g.
  /// `https://relay.example/join/<id>#k=<key>`.
  String toUrl() {
    final base = relayBaseUrl.endsWith('/')
        ? relayBaseUrl.substring(0, relayBaseUrl.length - 1)
        : relayBaseUrl;
    return '$base/join/$partyId#k=$keyString';
  }

  /// Parse a link produced by [toUrl]; returns null if it isn't a valid join
  /// link (missing party id or key).
  static PartyJoinLink? parse(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    final segs = uri.pathSegments;
    final i = segs.indexOf('join');
    if (i < 0 || i + 1 >= segs.length) return null;
    final partyId = segs[i + 1];
    if (partyId.isEmpty) return null;

    // Key from the fragment: `k=<key>` (or a bare fragment).
    final frag = uri.fragment;
    String? key;
    if (frag.contains('=')) {
      for (final part in frag.split('&')) {
        final kv = part.split('=');
        if (kv.length == 2 && kv[0] == 'k' && kv[1].isNotEmpty) key = kv[1];
      }
    } else if (frag.isNotEmpty) {
      key = frag;
    }
    if (key == null) return null;

    final base = '${uri.scheme}://${uri.authority}';
    return PartyJoinLink(
      relayBaseUrl: base,
      partyId: partyId,
      keyString: key,
    );
  }
}
