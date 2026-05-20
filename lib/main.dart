import 'package:flutter/material.dart';

import 'app.dart';
import 'database/db_factory.dart';
import 'database/database_service.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabaseFactory();
  await DatabaseService.instance.initDatabase();
  await ThemeController.instance.load();
  runApp(const ChiaCpdApp());
}
