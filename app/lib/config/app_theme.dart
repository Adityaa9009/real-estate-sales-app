import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppColors {
  // Core palette (exact values specified)
  static const Color primary = Color(0xFFFF4B4B); // Hot Coral
  static const Color secondary = Color(0xFFFF7A00); // Vivid Tangerine
  static const Color accent = Color(0xFFFFC043); // Bright Marigold
  static const Color background = Color(0xFFF8F9FA); // Clean Off-White
  static const Color textPrimary = Color(0xFF1A1D1F); // Ink Black

  // Derived surfaces (lighter/darker steps from background, for card layering)
  static const Color surface = Color(0xFFFFFFFF); // Pure White (cards, sheets)
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F3F5); // Recessed areas, input fills, stat backgrounds
  static const Color surfaceBorder = Color(0xFFE3E6E8); // Light neutral border

  // Text & semantic hierarchy
  static const Color textSecondary = Color(0xFF5B6165); // Muted dark gray for secondary labels
  static const Color textMuted = Color(0xFF8A9099); // Hints, timestamps, disabled

  // Status (tuned to sit cleanly on light surfaces)
  static const Color danger = Color(0xFFE0294B); // Rich crimson
  static const Color success = Color(0xFF1FA971); // Deep emerald
  static const Color info = Color(0xFF3D8BFF); // Cerulean
  static const Color warning = accent; // Bright Marigold

  // Role accents (clean, high-contrast badges)
  static const Color roleAdmin = Color(0xFFE0294B); // Crimson
  static const Color roleExecutive = Color(0xFF7C5CFC); // Purple
  static const Color roleInsideSales = Color(0xFF3D8BFF); // Blue
  static const Color roleOutsideSales = Color(0xFF1FA971); // Emerald

  // Skeleton / Shimmer (for light backgrounds)
  static const Color shimmerBase = Color(0xFFE9ECEF);
  static const Color shimmerHighlight = Color(0xFFF8F9FA);

  // Backward-compatible color aliases
  static const Color primaryDark = Color(0xFFD9383A);
  static const Color primaryLight = Color(0xFFFF7A00);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary], // Coral -> Tangerine
  );

  static const LinearGradient warmAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, accent], // Tangerine -> Marigold
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1FA971), Color(0xFF2DD4BF)],
  );

  static const LinearGradient glassBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1F000000), Color(0x0A000000)], // subtle dark border for light cards
  );

  static BoxShadow softGlow(Color color, {double blur = 14}) => BoxShadow(
    color: color.withAlpha(35),
    blurRadius: blur,
    spreadRadius: -2,
    offset: const Offset(0, 4),
  );
}

class CardStyles {
  /// Primary elevated card (hero metric cards, chart cards, primary modal surfaces)
  /// Rich layered surface with refined border, ambient shadow, and optional accent glow.
  static BoxDecoration primary({
    Color? color,
    Color? borderColor,
    double borderRadius = 18.0,
    LinearGradient? gradient,
    Color? glowColor,
  }) => BoxDecoration(
    color: gradient == null ? (color ?? AppColors.surfaceCard) : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ?? (glowColor != null ? glowColor.withAlpha(90) : AppColors.surfaceBorder),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(25),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
      if (glowColor != null)
        BoxShadow(
          color: glowColor.withAlpha(20),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
    ],
  );

  /// Secondary card (standard list items, customer tiles, employee cards, secondary stat cards)
  /// Clean surface with crisp border and smooth subtle elevation.
  static BoxDecoration secondary({
    Color? color,
    Color? borderColor,
    double borderRadius = 14.0,
    LinearGradient? gradient,
  }) => BoxDecoration(
    color: gradient == null ? (color ?? AppColors.surfaceCard) : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ?? AppColors.surfaceBorder,
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(15),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Flat card (embedded sub-panels, chip bars, inner form containers, dialog content blocks)
  /// Clean surface background with subtle border and zero shadow.
  static BoxDecoration flat({
    Color? color,
    Color? borderColor,
    double borderRadius = 12.0,
  }) => BoxDecoration(
    color: color ?? AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ?? AppColors.surfaceBorder,
      width: 1.0,
    ),
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
      ),
      displayMedium: GoogleFonts.sora(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.6,
      ),
      displaySmall: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.surfaceBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(40),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
