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
    final baseTextTheme = GoogleFonts.interTextTheme();

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
        displayLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal, color: textSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shadowColor: const Color(0x0A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFFF1F5F9),
        side: const BorderSide(color: borderColor),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
      ),
    );
  }
}



