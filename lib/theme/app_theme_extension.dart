import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Semantic colors that adapt to light and dark mode.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.card,
    required this.header,
    required this.primaryTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.warningSurface,
    required this.successSurface,
    required this.errorSurface,
    required this.cardShadow,
    required this.chipUnselectedBackground,
    required this.inputFill,
  });

  final Color card;
  final Color header;
  final Color primaryTint;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color warningSurface;
  final Color successSurface;
  final Color errorSurface;
  final List<BoxShadow> cardShadow;
  final Color chipUnselectedBackground;
  final Color inputFill;

  static final light = AppThemeExtension(
    card: AppColors.surface,
    header: AppColors.surface,
    primaryTint: AppColors.primaryLight,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    border: AppColors.border,
    warningSurface: AppColors.warningSurface,
    successSurface: AppColors.successSurface,
    errorSurface: AppColors.errorSurface,
    cardShadow: AppShadows.lightCard,
    chipUnselectedBackground: Colors.white,
    inputFill: Colors.white,
  );

  static final dark = AppThemeExtension(
    card: const Color(0xFF1E2433),
    header: const Color(0xFF161B26),
    primaryTint: const Color(0xFF0D3A52),
    textPrimary: const Color(0xFFF3F4F6),
    textSecondary: const Color(0xFF9CA3AF),
    textHint: const Color(0xFF6B7280),
    border: const Color(0xFF374151),
    warningSurface: const Color(0xFF422006),
    successSurface: const Color(0xFF052E1C),
    errorSurface: const Color(0xFF450A0A),
    cardShadow: AppShadows.darkCard,
    chipUnselectedBackground: const Color(0xFF252B3B),
    inputFill: const Color(0xFF252B3B),
  );

  @override
  AppThemeExtension copyWith({
    Color? card,
    Color? header,
    Color? primaryTint,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? warningSurface,
    Color? successSurface,
    Color? errorSurface,
    List<BoxShadow>? cardShadow,
    Color? chipUnselectedBackground,
    Color? inputFill,
  }) {
    return AppThemeExtension(
      card: card ?? this.card,
      header: header ?? this.header,
      primaryTint: primaryTint ?? this.primaryTint,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      warningSurface: warningSurface ?? this.warningSurface,
      successSurface: successSurface ?? this.successSurface,
      errorSurface: errorSurface ?? this.errorSurface,
      cardShadow: cardShadow ?? this.cardShadow,
      chipUnselectedBackground:
          chipUnselectedBackground ?? this.chipUnselectedBackground,
      inputFill: inputFill ?? this.inputFill,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      card: Color.lerp(card, other.card, t)!,
      header: Color.lerp(header, other.header, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      chipUnselectedBackground: Color.lerp(
            chipUnselectedBackground, other.chipUnselectedBackground, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appExt =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
