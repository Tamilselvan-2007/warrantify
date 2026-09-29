import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color inkNavy = Color(0xFF14213D);
  static const Color parchment = Color(0xFFF7F3EC);
  static const Color craftAmber = Color(0xFFC97B3D);
  static const Color clinicalTeal = Color(0xFF2A9D8F);
  static const Color sealCrimson = Color(0xFFA13D3D);
  static const Color slate = Color(0xFF6B7280);

  // Category-specific accents (used for card tags, category chips)
  static Color forCategory(String? category) {
    switch (category) {
      case 'furniture':
        return craftAmber;
      case 'dental':
        return clinicalTeal;
      default:
        return slate;
    }
  }
}