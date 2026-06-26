import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFF5F0E8);
  static const warmBrown = Color(0xFF8B6914);
  static const darkBrown = Color(0xFF4A3000);
  static const forestGreen = Color(0xFF2D4A3E);
  static const lightGreen = Color(0xFF4A7C6F);
  static const paperWhite = Color(0xFFFAF7F2);
  static const inkBlack = Color(0xFF1A1410);
  static const warmGray = Color(0xFF9E9189);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.forestGreen,
          onPrimary: Colors.white,
          secondary: AppColors.warmBrown,
          onSecondary: Colors.white,
          surface: AppColors.paperWhite,
          onSurface: AppColors.inkBlack,
          error: const Color(0xFFB00020),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.cream,
        textTheme: GoogleFonts.notoSerifTcTextTheme().copyWith(
          headlineLarge: GoogleFonts.notoSerifTc(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.inkBlack,
          ),
          bodyLarge: GoogleFonts.notoSerifTc(
            fontSize: 16,
            height: 1.8,
            color: AppColors.inkBlack,
          ),
          bodyMedium: GoogleFonts.notoSerifTc(
            fontSize: 14,
            height: 1.7,
            color: AppColors.inkBlack,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.paperWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.warmBrown.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.warmBrown.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.forestGreen, width: 1.5),
          ),
        ),
      );
}
