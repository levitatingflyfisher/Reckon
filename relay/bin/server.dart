import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'package:reckonparty_relay/relay.dart';

/// Entry point for the ReckonParty sync relay.
///
/// Run locally:    dart run bin/server.dart
/// Configure:      PORT (default 8080), HOST (default 0.0.0.0)
///
/// The relay is content-agnostic: it stores and returns opaque, client-encrypted
/// blobs and never interprets decision content. See README.md.
Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final host = Platform.environment['HOST'] ?? '0.0.0.0';

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(createRelayHandler(InMemoryBlobStore()));

  final server = await io.serve(handler, host, port);
  stdout.writeln('ReckonParty relay listening on http://${server.address.host}:'
      '${server.port}');
}
