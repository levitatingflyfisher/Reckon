import 'llm_service.dart';

/// Web: the stove is unreachable from a browser — an https PWA calling a LAN
/// http endpoint is blocked as mixed content — so a stove forecaster can
/// never be built here. Nothing in this file imports domovoi (whose barrel
/// pulls dart:io).
LlmService? buildStoveLlmService({
  required String host,
  int? port,
  required String phrase,
}) =>
    null;
