import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What a device needs to keep talking to a synced party: which relay hosts it
/// and the symmetric key to decrypt its blobs.
class PartySyncInfo {
  const PartySyncInfo({required this.baseUrl, required this.keyString});
  final String baseUrl;
  final String keyString;

  Map<String, dynamic> toJson() => {'baseUrl': baseUrl, 'keyString': keyString};
  static PartySyncInfo fromJson(Map<String, dynamic> j) => PartySyncInfo(
        baseUrl: j['baseUrl'] as String,
        keyString: j['keyString'] as String,
      );
}

/// Per-party relay + key persistence. The key is the only secret; it lives on
/// device (and in share links), never on the relay.
///
/// Persistent groups get their own namespace (`putGroup`/`getGroup`): a
/// long-lived entry per group, held apart from the per-decision party keys,
/// which stay exactly as they were. Tonight the group namespace is a tested
/// seam, not yet a populated flow — group-manifest blobs on a relay (the
/// consumer of a long-lived group key) are deliberately deferred together
/// with relay deployment; LAN/pass-the-phone group flows need only the
/// per-party keys.
abstract class PartyKeyStore {
  Future<void> put(String partyId, PartySyncInfo info);
  Future<PartySyncInfo?> get(String partyId);

  /// Store the long-lived sync entry for a persistent group.
  Future<void> putGroup(String groupId, PartySyncInfo info);

  /// The group's long-lived sync entry, or null when this device has none.
  Future<PartySyncInfo?> getGroup(String groupId);
}

/// Secure-storage backed store (production). Keys sit in the platform keystore.
class SecurePartyKeyStore implements PartyKeyStore {
  SecurePartyKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  String _k(String partyId) => 'reckon.party_key.$partyId';
  String _g(String groupId) => 'reckon.group_key.$groupId';

  @override
  Future<void> put(String partyId, PartySyncInfo info) =>
      _storage.write(key: _k(partyId), value: jsonEncode(info.toJson()));

  @override
  Future<PartySyncInfo?> get(String partyId) => _read(_k(partyId));

  @override
  Future<void> putGroup(String groupId, PartySyncInfo info) =>
      _storage.write(key: _g(groupId), value: jsonEncode(info.toJson()));

  @override
  Future<PartySyncInfo?> getGroup(String groupId) => _read(_g(groupId));

  Future<PartySyncInfo?> _read(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return PartySyncInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

/// In-memory store for tests.
class InMemoryPartyKeyStore implements PartyKeyStore {
  final Map<String, PartySyncInfo> _parties = {};
  final Map<String, PartySyncInfo> _groups = {};
  @override
  Future<void> put(String partyId, PartySyncInfo info) async =>
      _parties[partyId] = info;
  @override
  Future<PartySyncInfo?> get(String partyId) async => _parties[partyId];
  @override
  Future<void> putGroup(String groupId, PartySyncInfo info) async =>
      _groups[groupId] = info;
  @override
  Future<PartySyncInfo?> getGroup(String groupId) async => _groups[groupId];
}
