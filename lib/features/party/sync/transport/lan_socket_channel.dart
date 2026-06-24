/// Real TCP transport for the LAN (same-Wi-Fi) party host.
///
/// This is the first concrete [DuplexChannel] backend: the host opens a
/// [ServerSocket] and each connecting peer becomes a channel; the relay engine
/// ([ChannelRelayHost] / [ChannelPartyRelay]) then runs over it unchanged.
///
/// TCP is a byte stream with no message boundaries, so messages are
/// length-framed (4-byte big-endian length prefix + payload) and reassembled on
/// receive — satisfying [DuplexChannel]'s one-send-one-event contract.
///
/// Uses `dart:io`, so it is mobile/desktop only — it must not be imported by
/// web-reachable code. Web peers use the cloud relay instead.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'duplex_channel.dart';

/// A [DuplexChannel] over a connected TCP [Socket] with length framing.
class SocketDuplexChannel implements DuplexChannel {
  SocketDuplexChannel(this._socket) {
    _socket.listen(
      _onData,
      onError: (_) => _incoming.close(),
      onDone: () {
        if (!_incoming.isClosed) _incoming.close();
      },
      cancelOnError: true,
    );
  }

  /// Largest single message accepted, to bound buffering against a malformed or
  /// hostile peer (party/ballot blobs are well under this).
  static const int maxMessageBytes = 8 * 1024 * 1024;

  final Socket _socket;
  final _incoming = StreamController<Uint8List>.broadcast();
  final _buffer = BytesBuilder(copy: false);
  int? _expected; // payload length once the 4-byte header is read

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  void send(Uint8List message) {
    final header = ByteData(4)..setUint32(0, message.length, Endian.big);
    _socket.add(header.buffer.asUint8List());
    _socket.add(message);
  }

  void _onData(Uint8List chunk) {
    _buffer.add(chunk);
    // Drain as many complete frames as the buffer currently holds.
    while (true) {
      final bytes = _buffer.toBytes();
      if (_expected == null) {
        if (bytes.length < 4) {
          _restore(bytes);
          return;
        }
        final len = ByteData.sublistView(bytes, 0, 4).getUint32(0, Endian.big);
        if (len > maxMessageBytes) {
          _incoming.close();
          _socket.destroy();
          return;
        }
        _expected = len;
        _restore(Uint8List.sublistView(bytes, 4));
        continue;
      }
      if (bytes.length < _expected!) {
        _restore(bytes);
        return;
      }
      final message = Uint8List.sublistView(bytes, 0, _expected!);
      _restore(Uint8List.sublistView(bytes, _expected!));
      _expected = null;
      if (!_incoming.isClosed) _incoming.add(Uint8List.fromList(message));
    }
  }

  void _restore(Uint8List remaining) {
    _buffer.clear();
    if (remaining.isNotEmpty) _buffer.add(remaining);
  }

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) await _incoming.close();
    await _socket.close();
  }
}

/// The LAN host's listening socket. Each peer that connects becomes a
/// [DuplexChannel] on [connections]; the caller attaches a [ChannelRelayHost]
/// to each one.
class LanSocketHost {
  LanSocketHost._(this._server);

  final ServerSocket _server;
  final _connections = StreamController<DuplexChannel>.broadcast();
  StreamSubscription<Socket>? _sub;

  /// Bind a host on [address] (default: all interfaces, so LAN peers can reach
  /// it) and [port] (0 = ephemeral). Read [port] afterwards to share it.
  static Future<LanSocketHost> bind({
    Object address = '0.0.0.0',
    int port = 0,
  }) async {
    final server = await ServerSocket.bind(address, port);
    final host = LanSocketHost._(server);
    host._sub = server.listen(
      (socket) => host._connections.add(SocketDuplexChannel(socket)),
    );
    return host;
  }

  /// The bound port — put this in the share link / QR alongside the host IP.
  int get port => _server.port;

  /// One [DuplexChannel] per connected peer.
  Stream<DuplexChannel> get connections => _connections.stream;

  Future<void> close() async {
    await _sub?.cancel();
    await _connections.close();
    await _server.close();
  }
}

/// Joiner side: connect to a LAN host at [host]:[port] and get a channel.
Future<DuplexChannel> connectToLanHost(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final socket = await Socket.connect(host, port, timeout: timeout);
  return SocketDuplexChannel(socket);
}
