import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF0082C8);
  static const _surface = Color(0xFFF1F1F1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        surface: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 28,
          color: Color(0xFF0D1321),
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Color(0xFF0D1321),
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xFF0D1321),
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Color(0xFF4A5570),
        ),
      ),
    );
  }
}
