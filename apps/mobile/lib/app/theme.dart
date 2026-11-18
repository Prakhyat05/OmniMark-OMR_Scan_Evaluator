import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens directly imported from Stitch AI "Academic Precision" design system.
class AppColors {
  static const Color primary = Color(0xFF006E1C);
  static const Color primaryContainer = Color(0xFF4CAF50);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF003C0B);

  static const Color secondary = Color(0xFF2A6B2C);
  static const Color secondaryContainer = Color(0xFFACF4A4);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF556158);
  static const Color tertiaryContainer = Color(0xFF929E94);
  static const Color softMint = Color(0xFFE8F5E9);

  static const Color background = Color(0xFFFCF9F8);
  static const Color surface = Color(0xFFFCF9F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color surfaceContainer = Color(0xFFF0EDED);
  static const Color surfaceContainerHigh = Color(0xFFEAE7E7);
  static const Color surfaceContainerHighest = Color(0xFFE5E2E1);

  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF3F4A3C);
  static const Color outline = Color(0xFF6F7A6B);
  static const Color outlineVariant = Color(0xFFBECAB9);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.hankenGroteskTextTheme().copyWith(
      displayLarge: GoogleFonts.hankenGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.onSurface,
      ),
      headlineLarge: GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      titleLarge: GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      bodyLarge: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      labelMedium: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onError: AppColors.onError,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.25),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.hankenGrotesk(
          color: AppColors.onSurfaceVariant.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
