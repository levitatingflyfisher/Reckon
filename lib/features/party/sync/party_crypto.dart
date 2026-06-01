import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// On-device authenticated encryption for ReckonParty sync (AES-GCM-256).
///
/// The party key never leaves the device except inside a share link's URL
/// fragment (see `party_link.dart`), which is never sent to a server. The relay
/// therefore only ever holds ciphertext it cannot read — practical privacy: a
/// breach or subpoena of the relay reveals nothing.
class PartyCrypto {
  PartyCrypto(this._key);

  /// Build from a base64url key string (as carried in a join link).
  factory PartyCrypto.fromKeyString(String keyB64) =>
      PartyCrypto(SecretKey(base64Url.decode(_pad(keyB64))));

  final SecretKey _key;

  static final AesGcm _algo = AesGcm.with256bits();
  static const _nonceLen = 12;
  static const _macLen = 16;

  /// Generate a fresh random party key and its base64url string form.
  static Future<({PartyCrypto crypto, String keyString})> generate() async {
    final key = await _algo.newSecretKey();
    final bytes = await key.extractBytes();
    return (
      crypto: PartyCrypto(key),
      keyString: base64Url.encode(bytes).replaceAll('=', ''),
    );
  }

  /// Encrypt a JSON object into a self-contained blob (nonce + ciphertext + mac).
  Future<Uint8List> encryptJson(Map<String, dynamic> data) async {
    final clear = utf8.encode(jsonEncode(data));
    final box = await _algo.encrypt(clear, secretKey: _key);
    return Uint8List.fromList(box.concatenation());
  }

  /// Decrypt a blob produced by [encryptJson]. Throws if the key is wrong or the
  /// blob was tampered with (GCM authentication failure).
  Future<Map<String, dynamic>> decryptJson(Uint8List blob) async {
    final box = SecretBox.fromConcatenation(
      blob,
      nonceLength: _nonceLen,
      macLength: _macLen,
    );
    final clear = await _algo.decrypt(box, secretKey: _key);
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  }

  static String _pad(String b64) {
    final mod = b64.length % 4;
    return mod == 0 ? b64 : b64 + '=' * (4 - mod);
  }
}
