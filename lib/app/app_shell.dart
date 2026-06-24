import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int index = 0;
    if (location.startsWith('/record')) index = 1;
    if (location.startsWith('/glossary')) index = 2;
    if (location.startsWith('/settings')) index = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/record');
            case 2:
              context.go('/glossary');
            case 3:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), label: 'Record'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), label: 'Techniques'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
