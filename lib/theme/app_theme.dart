import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color backgroundBase = Color(0xFF0A0A0A);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color inputFill = Color(0xFF222222);
  
  // Accents
  static const Color primaryGold = Color(0xFFFAB95B);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  
  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);

  // Legacy mappings for old UI refactoring
  static const Color primaryBlue = primaryGold;
  static const Color primaryBlueDark = textPrimary;
  static const Color accentYellow = primaryGold;
  static const Color errorRed = error;
  static const Color textGrey = textSecondary;
  static const Color white = inputFill;
  static const Color textDark = backgroundBase;
}

class AppDimens {
  static const double gridBase = 8.0;
  static const double pageMargin = 20.0;
  static const double sectionGap = 24.0;
  
  // Radii
  static const double radiusCard = 16.0;
  static const double radiusInput = 10.0;
  static const double radiusButton = 28.0;
  static const double radiusPill = 99.0;
}

class AppTextStyles {
  // Headings (Bold)
  static TextStyle h1 = GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle h2 = GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle h3 = GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  
  // Labels (Medium)
  static TextStyle labelLarge = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle labelMedium = GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle labelSmall = GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  
  // Body (Regular)
  static TextStyle bodyLarge = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
  static TextStyle bodyMedium = GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryGold,
      scaffoldBackgroundColor: AppColors.backgroundBase,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGold,
        secondary: AppColors.primaryGold,
        surface: AppColors.surfaceCard,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
      ),
    );
  }
}
