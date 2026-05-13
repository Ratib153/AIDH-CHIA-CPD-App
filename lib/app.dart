import 'package:flutter/material.dart';

import 'features/activities/activities_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/export/export_screen.dart';
import 'features/profile/profile_screen.dart';
import 'theme/app_theme.dart';

class ChiaCpdApp extends StatelessWidget {
  const ChiaCpdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPD Tracker',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AppScaffold(),
    );
  }
}

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ActivitiesScreen(),
    ProfileScreen(),
    ExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primaryLight,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.primary, size: 24);
              }
              return const IconThemeData(color: AppColors.textHint, size: 24);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final base = const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
              if (states.contains(WidgetState.selected)) {
                return base.copyWith(color: AppColors.primary);
              }
              return base.copyWith(color: AppColors.textHint);
            }),
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
