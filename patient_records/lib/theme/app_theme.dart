import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra-Modern Luxury Medical Palette (Light Executive)
  static const Color primaryTeal = Color(0xFF0D9488); // Deep Emerald Teal
  static const Color primaryTealHover = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0F172A); // Deep Slate Navy
  static const Color secondaryNavy = Color(0xFF0F172A); // Legacy alias

  static const Color accentCyan = Color(0xFF0284C7); // Sky Blue
  static const Color accentIndigo = Color(0xFF4F46E5); // Royal Indigo
  static const Color accentRose = Color(0xFFE11D48); // Crisp Rose
  static const Color accentEmerald = Color(0xFF16A34A); // Forest Emerald
  static const Color accentAmber = Color(0xFFD97706); // Gold Amber

  static const Color backgroundLight = Color(0xFFF8FAFC); // Crisp Slate White
  static const Color cardSurface = Colors.white;
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Status Colors
  static const Color statusWaiting = Color(0xFFD97706); // Amber Gold
  static const Color statusInConsultation = Color(0xFF2563EB); // Royal Blue
  static const Color statusCompleted = Color(0xFF16A34A); // Emerald Green
  static const Color statusPaid = Color(0xFF16A34A);
  static const Color statusPending = Color(0xFFDC2626);

  // Clean Professional Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Executive Theme Configuration
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.light,
        primary: primaryTeal,
        secondary: accentCyan,
        surface: backgroundLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.2),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shadowColor: const Color(0x0A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFFF1F5F9),
        side: const BorderSide(color: borderColor),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
      ),
    );
  }
}



