import 'package:flutter_gemma/flutter_gemma.dart';

/// Native: flutter_gemma 0.13.x requires this one-time init before
/// `installModel` / `getActiveModel` are used — without it, starting a case
/// throws "Bad state: FlutterGemma not initialized!".
Future<void> initGemma() => FlutterGemma.initialize();
