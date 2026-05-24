import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'auth/auth_service.dart';
import 'database/db_factory.dart';
import 'database/database_service.dart';
import 'firebase_options.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional until flutterfire configure fills firebase_options.dart.
  if (DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthService.instance.init();
  } else {
    debugPrint(
      'Firebase skipped: run flutterfire configure for project chia-cpd-tracker',
    );
  }

  await initDatabaseFactory();
  await DatabaseService.instance.initDatabase();
  await ThemeController.instance.load();
  runApp(const ChiaCpdApp());
}
