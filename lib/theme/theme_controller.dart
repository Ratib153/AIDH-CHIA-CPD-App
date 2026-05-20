import 'package:flutter/material.dart';

import '../database/database_service.dart';

const _kThemeModeKey = 'settings.themeMode';

/// Global theme mode state, persisted in SQLite app_settings.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final stored =
        await DatabaseService.instance.getSetting(_kThemeModeKey);
    if (stored == 'dark') {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setDark(bool enabled) async {
    _mode = enabled ? ThemeMode.dark : ThemeMode.light;
    await DatabaseService.instance.setSetting(
      _kThemeModeKey,
      enabled ? 'dark' : 'light',
    );
    notifyListeners();
  }
}
