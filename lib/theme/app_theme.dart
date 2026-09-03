import 'package:flutter/material.dart';

/// Colors and text styles pulled from the reference PDF screenshots
/// (dark sidebar, orange accent, rounded dark input fields).
class AppColors {
  static const Color background = Color(0xFF0D0D14); // near-black main bg
  static const Color sidebar = Color(0xFF000000); // pure black sidebar
  static const Color card = Color(0xFF1A1A24); // dark card / row background
  static const Color inputField = Color(0xFF1E1E29); // input box background
  static const Color accentOrange = Color(0xFFF5A623); // active tab / title
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0AA);
  static const Color divider = Color(0xFF2A2A36);
  static const Color danger = Color(0xFFE05A5A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentOrange,
        surface: AppColors.card,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.accentOrange,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputField,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
