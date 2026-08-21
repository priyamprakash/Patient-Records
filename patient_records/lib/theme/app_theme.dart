import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant Medical Palette
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color secondaryNavy = Color(0xFF0F172A);
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color glassSurface = Color(0xF2FFFFFF);

  // Status Colors
  static const Color statusWaiting = Color(0xFFD97706);
  static const Color statusInConsultation = Color(0xFF2563EB);
  static const Color statusCompleted = Color(0xFF059669);
  static const Color statusPaid = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFE11D48);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorderGradient = LinearGradient(
    colors: [Color(0x80FFFFFF), Color(0x330D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentCyan,
        surface: backgroundLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: secondaryNavy),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: secondaryNavy),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: secondaryNavy),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: secondaryNavy),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: glassSurface,
        elevation: 3,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1F0F766E), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13),
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.teal.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.teal.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: Colors.teal.shade50,
        side: BorderSide(color: Colors.teal.shade100),
      ),
    );
  }
}
