import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.inkNavy,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.inkNavy,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.inkNavy,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.inkNavy,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.slate,
        ),
        labelSmall: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.slate,
          letterSpacing: 0.5,
        ),
      );

  static const TextStyle mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.inkNavy,
  );
}