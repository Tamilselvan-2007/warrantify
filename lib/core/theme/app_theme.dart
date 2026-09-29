import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.parchment,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.inkNavy,
          primary: AppColors.inkNavy,
          secondary: AppColors.craftAmber,
          error: AppColors.sealCrimson,
          surface: AppColors.parchment,
        ),
        textTheme: AppTypography.textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.parchment,
          foregroundColor: AppColors.inkNavy,
          elevation: 0,
          titleTextStyle: AppTypography.textTheme.headlineMedium,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.inkNavy,
            foregroundColor: AppColors.parchment,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            textStyle: AppTypography.textTheme.titleLarge?.copyWith(
              color: AppColors.parchment,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            borderSide: BorderSide(color: AppColors.slate.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            borderSide: BorderSide(color: AppColors.slate.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            borderSide: const BorderSide(color: AppColors.inkNavy, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ),
      );
}