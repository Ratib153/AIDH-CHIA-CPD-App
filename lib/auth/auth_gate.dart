import 'package:flutter/material.dart';

import '../app_scaffold.dart';
import '../features/auth/login_screen.dart';
import '../firebase_options.dart';
import 'auth_service.dart';

/// Shows [LoginScreen] when Firebase is configured and the user is signed out;
/// otherwise shows the main app shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DefaultFirebaseOptions.isConfigured) {
      return const AppScaffold();
    }

    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.isSignedIn) {
          return const AppScaffold();
        }
        return const LoginScreen();
      },
    );
  }
}
