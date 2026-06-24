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
abstract class PartyKeyStore {
  Future<void> put(String partyId, PartySyncInfo info);
  Future<PartySyncInfo?> get(String partyId);
}

/// Secure-storage backed store (production). Keys sit in the platform keystore.
class SecurePartyKeyStore implements PartyKeyStore {
  SecurePartyKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  String _k(String partyId) => 'reckon.party_key.$partyId';

  @override
  Future<void> put(String partyId, PartySyncInfo info) =>
      _storage.write(key: _k(partyId), value: jsonEncode(info.toJson()));

  @override
  Future<PartySyncInfo?> get(String partyId) async {
    final raw = await _storage.read(key: _k(partyId));
    if (raw == null) return null;
    return PartySyncInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

/// In-memory store for tests.
class InMemoryPartyKeyStore implements PartyKeyStore {
  final Map<String, PartySyncInfo> _m = {};
  @override
  Future<void> put(String partyId, PartySyncInfo info) async =>
      _m[partyId] = info;
  @override
  Future<PartySyncInfo?> get(String partyId) async => _m[partyId];
}
