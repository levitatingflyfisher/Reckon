// Platform-selected invite action: the native build hosts the party on the
// LAN (dart:io), the web build renders nothing (browsers can't host).
export 'party_host_action_stub.dart'
    if (dart.library.io) 'party_host_action_io.dart';
