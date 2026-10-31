import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuraColors {
  // Brand Blues & Neons
  static const Color primaryBlue = Color(0xFF0066FF); // Electric YouTube Blue
  static const Color primaryBlueLight = Color(0xFF2979FF);
  static const Color accentCyan = Color(0xFF00D2FF);   // Neon Cyan glow
  static const Color glowBlue = Color(0x330066FF);
  static const Color liveRed = Color(0xFFFF2A2A);

  // Obsidian Dark Surfaces
  static const Color obsidianBase = Color(0xFF080B11);       // Deepest black-blue
  static const Color surface = Color(0xFF0E131F);            // Sheet & card surface
  static const Color surfaceHigh = Color(0xFF161E30);        // Raised elements
  static const Color surfaceContainerLow = Color(0xFF1A2338); // Inputs & containers
  static const Color outline = Color(0xFF25334E);            // Subtle dividers & borders
  static const Color outlineGlow = Color(0x660066FF);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF0F4FC);
  static const Color textSecondary = Color(0xFFA0B0D0);
  static const Color textMuted = Color(0xFF627394);
}

class AuraTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AuraColors.obsidianBase,
      primaryColor: AuraColors.primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: AuraColors.primaryBlue,
        secondary: AuraColors.accentCyan,
        surface: AuraColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AuraColors.textPrimary,
        outline: AuraColors.outline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AuraColors.obsidianBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AuraColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AuraColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AuraColors.surface,
        selectedItemColor: AuraColors.primaryBlueLight,
        unselectedItemColor: AuraColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AuraColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AuraColors.outline, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AuraColors.surface,
        modalBackgroundColor: AuraColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AuraColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AuraColors.primaryBlueLight,
        inactiveTrackColor: AuraColors.outline,
        thumbColor: AuraColors.primaryBlueLight,
        overlayColor: AuraColors.glowBlue,
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AuraColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AuraColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AuraColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AuraColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AuraColors.textMuted,
        ),
      ),
    );
  }
}
