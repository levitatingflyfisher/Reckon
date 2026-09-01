import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../shared/theme/reckon_theme.dart';

/// What Reckon shows when a startup step (seeding the reference classes,
/// notifications, the onboarding flag) fails before the app can build.
/// A sentence first; the exception only behind Details (fleet error ruling).
class StartupFailure extends StatelessWidget {
  const StartupFailure({super.key, required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ReckonTheme.light(),
      darkTheme: ReckonTheme.hearthDark(),
      home: Scaffold(
        body: OhPage(
          child: OhErrorState.fromError(
            error,
            stackTrace: stackTrace,
            title: "Reckon couldn’t start",
            message: 'Something on this device got in the way while Reckon '
                'was opening. Your decisions are not affected. Close Reckon '
                'and open it again.',
          ),
        ),
      ),
    );
  }
}
