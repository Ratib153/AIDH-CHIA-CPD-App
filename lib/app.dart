import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class ChiaCpdApp extends StatelessWidget {
  const ChiaCpdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'CHIA CPD Tracker',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.mode,
          debugShowCheckedModeBanner: false,
          home: const AuthGate(),
        );
      },
    );
  }
}
