import 'package:flutter/material.dart';

import 'features/activities/activity_list_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/export/export_screen.dart';
import 'features/profile/profile_screen.dart';
import 'navigation/app_navigator.dart';

/// Main shell: bottom navigation across Home, Activities, Profile, and Export.
class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ActivityListScreen(),
    ProfileScreen(),
    ExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outline;

    return AppNavigator(
      selectTab: (index) => setState(() => _currentIndex = index),
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            border: Border(
              top: BorderSide(color: outline, width: 1),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 72,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Activities',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(Icons.file_download_outlined),
                selectedIcon: Icon(Icons.file_download),
                label: 'Export',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
