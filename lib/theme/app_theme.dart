import 'package:flutter/material.dart';

import 'app_theme_extension.dart';

class AppColors {
  static const primary = Color(0xFF0082C8);
  static const primaryDark = Color(0xFF005F94);
  static const primaryLight = Color(0xFFE6F3FB);
  static const success = Color(0xFF00A878);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const background = Color(0xFFF1F1F1);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0D1321);
  static const textSecondary = Color(0xFF4A5570);
  static const textHint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);

  static const warningSurface = Color(0xFFFEF3C7);
  static const successSurface = Color(0xFFD1FAE5);
  static const errorSurface = Color(0xFFFEE2E2);

  static const categoryPalette = <Color>[
    Color(0xFF0082C8),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF0EA5E9),
    Color(0xFF64748B),
  ];

  static Color forCategory(int categoryId) {
    final i = (categoryId - 1).clamp(0, categoryPalette.length - 1);
    return categoryPalette[i];
  }
}

class AppShadows {
  static List<BoxShadow> get lightCard => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get darkCard => [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  @Deprecated('Use context.appExt.cardShadow or AppShadows.lightCard')
  static List<BoxShadow> get card => lightCard;
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        extension: AppThemeExtension.light.copyWith(
          cardShadow: AppShadows.lightCard,
        ),
        scaffoldBg: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        inputFill: Colors.white,
        chipBg: Colors.white,
        navIndicator: AppColors.primaryLight,
        snackBarBg: AppColors.textPrimary,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        extension: AppThemeExtension.dark,
        scaffoldBg: const Color(0xFF0D1117),
        surface: const Color(0xFF1E2433),
        onSurface: const Color(0xFFF3F4F6),
        onSurfaceVariant: const Color(0xFF9CA3AF),
        outline: const Color(0xFF374151),
        inputFill: const Color(0xFF252B3B),
        chipBg: const Color(0xFF252B3B),
        navIndicator: const Color(0xFF0D3A52),
        snackBarBg: const Color(0xFF252B3B),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeExtension extension,
    required Color scaffoldBg,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required Color inputFill,
    required Color chipBg,
    required Color navIndicator,
    required Color snackBarBg,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [extension],
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        error: AppColors.error,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: extension.header,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        shape: Border(
          bottom: BorderSide(color: outline, width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 28,
          color: onSurface,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: onSurfaceVariant,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: extension.textHint,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        helperStyle: TextStyle(
          color: extension.textHint,
          fontSize: 12,
        ),
        labelStyle: TextStyle(color: onSurfaceVariant),
        hintStyle: TextStyle(color: extension.textHint),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 13,
          color: onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: navIndicator,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: extension.textHint, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColors.primary);
          }
          return base.copyWith(color: extension.textHint);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return inputFill;
        }),
        side: BorderSide(color: outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return extension.textHint;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBarBg,
        contentTextStyle: TextStyle(
          color: isDark ? extension.textPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return extension.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return outline;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(
          color: onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
