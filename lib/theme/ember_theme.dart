import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef SineColors = EmberColors;
typedef SineTheme = EmberTheme;

/// AuraTube v1.0.4 Production Monochromatic Design System
/// Inspired by Leica / Dieter Rams / Metrolist Pure-Black OLED minimalism.
class EmberColors {
  EmberColors._();

  // OLED Pure Black & Tonal Neutral Foundations
  static const Color obsidianBase = Color(0xFF000000);
  static const Color surface = Color(0xFF070708);
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerLow = Color(0xFF101012);
  static const Color surfaceContainer = Color(0xFF18181B);
  static const Color surfaceContainerHigh = Color(0xFF232327);
  static const Color surfaceContainerHighest = Color(0xFF2E2E34);

  // Monochromatic Accent System (Stark White, Platinum Silver, Brushed Titanium)
  static const Color monoWhite = Color(0xFFFFFFFF);
  static const Color monoPlatinum = Color(0xFFE4E4E7);
  static const Color monoSilver = Color(0xFFD4D4D8);
  static const Color monoTitanium = Color(0xFFA1A1AA);
  static const Color monoGraphite = Color(0xFF71717A);
  static const Color onAccent = Color(0xFF000000);

  // Mapped Primary Accents (Pure Monochromatic)
  static const Color primaryBlue = monoWhite;
  static const Color primaryBlueHi = monoPlatinum;
  static const Color secondaryCyan = monoSilver;
  static const Color secondaryAzure = monoTitanium;
  static const Color tertiaryBlue = monoSilver;

  // Convenience & Backward-Compatible Aliases
  static const Color electricBlue = monoWhite;
  static const Color electricBlueHi = monoPlatinum;
  static const Color charcoalCard = surfaceContainerLow;
  static const Color surfaceDark = surfaceContainer;
  static const Color glassBorder = outlineVariant;
  static const Color youtubeRed = monoWhite;

  static const Color primaryAmber = monoWhite;
  static const Color primaryAmberHi = monoPlatinum;
  static const Color secondaryHoney = monoSilver;
  static const Color secondaryOrange = monoTitanium;
  static const Color tertiaryGold = monoSilver;

  // Text & Content Hierarchy (WCAG AAA Monochrome Contrast)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // Architectural Hairlines & Borders
  static const Color outline = Color(0xFF3F3F46);
  static const Color outlineVariant = Color(0xFF27272A);
  static const Color borderSubtle = Color(0xFF1F1F23);
  static const Color hairline = Color(0x18FFFFFF);
  static const Color error = Color(0xFFE5484D);
  static const Color pulseBlue = monoWhite;
}

class EmberTheme {
  EmberTheme._();

  static ThemeData get darkTheme => buildTheme(useGoogleFonts: true);

  static ThemeData buildTheme({bool useGoogleFonts = true}) {
    TextTheme mergedTextTheme;
    if (useGoogleFonts) {
      try {
        final baseTextTheme = Typography.material2021().white;

        final headlineFont = GoogleFonts.soraTextTheme(baseTextTheme);
        final bodyFont = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
        final labelFont = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);

        mergedTextTheme = bodyFont.copyWith(
          displayLarge: headlineFont.displayLarge?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -1.0),
          displayMedium: headlineFont.displayMedium?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.6),
          displaySmall: headlineFont.displaySmall?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          headlineLarge: headlineFont.headlineLarge?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          headlineMedium: headlineFont.headlineMedium?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineSmall: headlineFont.headlineSmall?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleLarge: headlineFont.titleLarge?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: headlineFont.titleMedium?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w600),
          titleSmall: headlineFont.titleSmall?.copyWith(color: EmberColors.textSecondary, fontWeight: FontWeight.w500),
          bodyLarge: bodyFont.bodyLarge?.copyWith(color: EmberColors.textPrimary),
          bodyMedium: bodyFont.bodyMedium?.copyWith(color: EmberColors.textSecondary),
          bodySmall: bodyFont.bodySmall?.copyWith(color: EmberColors.textMuted),
          labelLarge: labelFont.labelLarge?.copyWith(color: EmberColors.textPrimary, fontWeight: FontWeight.w600),
          labelMedium: labelFont.labelMedium?.copyWith(color: EmberColors.textSecondary),
          labelSmall: labelFont.labelSmall?.copyWith(color: EmberColors.textMuted, letterSpacing: 0.6),
        );
      } catch (_) {
        mergedTextTheme = const TextTheme();
      }
    } else {
      mergedTextTheme = const TextTheme();
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: EmberColors.obsidianBase,
      canvasColor: EmberColors.surface,
      cardColor: EmberColors.surfaceContainerLow,
      dividerColor: EmberColors.outlineVariant,
      splashColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.04),
      colorScheme: const ColorScheme.dark(
        surface: EmberColors.surface,
        primary: EmberColors.monoWhite,
        secondary: EmberColors.monoSilver,
        tertiary: EmberColors.monoTitanium,
        error: EmberColors.error,
        onSurface: EmberColors.textPrimary,
        onPrimary: EmberColors.onAccent,
        onSecondary: EmberColors.onAccent,
      ),
      textTheme: mergedTextTheme,
      iconTheme: const IconThemeData(color: EmberColors.textSecondary, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: EmberColors.obsidianBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: mergedTextTheme.titleMedium?.copyWith(
          color: EmberColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: EmberColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EmberColors.monoWhite,
          foregroundColor: EmberColors.onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: mergedTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EmberColors.monoWhite,
          textStyle: mergedTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return EmberColors.onAccent;
          return EmberColors.monoTitanium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return EmberColors.monoWhite;
          return EmberColors.surfaceContainerHigh;
        }),
        trackOutlineColor: WidgetStateProperty.all(EmberColors.outlineVariant),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: EmberColors.monoWhite,
        inactiveTrackColor: EmberColors.surfaceContainerHigh,
        thumbColor: EmberColors.monoWhite,
        overlayColor: Colors.white.withValues(alpha: 0.14),
        trackHeight: 3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: EmberColors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: EmberColors.outlineVariant, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: EmberColors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EmberColors.surfaceContainerHigh,
        contentTextStyle: const TextStyle(color: EmberColors.textPrimary, fontSize: 13),
        actionTextColor: EmberColors.monoWhite,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: EmberColors.outlineVariant),
        ),
      ),
    );
  }
}
