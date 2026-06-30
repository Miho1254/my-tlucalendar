import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ════════════════════════════════════════════════════════
  // ZINC PALETTE — True Dark / OLED Black (Shadcn standard)
  // ════════════════════════════════════════════════════════
  static const Color _black     = Color(0xFF000000); // OLED Pure Black
  static const Color _zinc950   = Color(0xFF09090B); // Card surface
  static const Color _zinc900   = Color(0xFF18181B); // Secondary/Muted bg
  static const Color _zinc800   = Color(0xFF27272A); // Hairline border
  static const Color _zinc400   = Color(0xFFA1A1AA); // Muted / Caption
  static const Color _white     = Color(0xFFFAFAFA); // Primary foreground
  static const Color _indigo500 = Color(0xFF6366F1); // Brand accent
  static const Color _red500    = Color(0xFFEF4444); // Destructive

  // Light palette
  static const Color _lightBg     = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE4E4E7); // Zinc 200
  static const Color _lightText   = Color(0xFF09090B); // Zinc 950
  static const Color _lightMuted  = Color(0xFF71717A); // Zinc 500

  // ════════════════════════════════════════════════════════
  // FORUI THEME — DARK
  // Strategy: take FThemes.zinc.dark.touch, then rebuild
  // FThemeData with our custom FColors (correct API pattern).
  // ════════════════════════════════════════════════════════
  static FThemeData get darkForui {
    final base = FThemes.zinc.dark.touch;

    // Build custom FColors from scratch using the known Forui FColors fields
    final customColors = FColors(
      brightness: Brightness.dark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      barrier: const Color(0x80000000),
      background: _black,
      foreground: _white,
      primary: _indigo500,
      primaryForeground: _white,
      secondary: _zinc900,
      secondaryForeground: _white,
      muted: _zinc900,
      mutedForeground: _zinc400,
      destructive: _red500,
      destructiveForeground: _white,
      error: _red500,
      errorForeground: _white,
      card: _zinc900,
      border: _zinc800,
    );

    // Rebuild FThemeData with custom colors, inherit everything else from base
    return FThemeData(
      colors: customColors,
      touch: true,
      typography: base.typography,
      style: base.style,
      hapticFeedback: base.hapticFeedback,
    );
  }

  // ════════════════════════════════════════════════════════
  // FORUI THEME — LIGHT
  // ════════════════════════════════════════════════════════
  static FThemeData get lightForui {
    final base = FThemes.zinc.light.touch;

    final customColors = FColors(
      brightness: Brightness.light,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      barrier: const Color(0x33000000),
      background: _lightBg,
      foreground: _lightText,
      primary: _lightText,
      primaryForeground: _lightBg,
      secondary: const Color(0xFFF4F4F5), // Zinc 100
      secondaryForeground: _lightText,
      muted: const Color(0xFFF4F4F5),
      mutedForeground: _lightMuted,
      destructive: _red500,
      destructiveForeground: _white,
      error: _red500,
      errorForeground: _white,
      card: _lightBg,
      border: _lightBorder,
    );

    return FThemeData(
      colors: customColors,
      touch: true,
      typography: base.typography,
      style: base.style,
      hapticFeedback: base.hapticFeedback,
    );
  }

  // ════════════════════════════════════════════════════════
  // MATERIAL FALLBACK — DARK
  // Synced with Forui dark palette so 3rd-party widgets
  // (TableCalendar, etc.) inherit the right colors
  // ════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _black,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        surface: _zinc900,
        onSurface: _white,
        primary: _indigo500,
        onPrimary: _white,
        primaryContainer: Color(0xFF1E1B4B),
        onPrimaryContainer: _white,
        secondary: _zinc900,
        onSecondary: _white,
        secondaryContainer: _zinc800,
        onSecondaryContainer: _zinc400,
        tertiary: _indigo500,
        onTertiary: _white,
        tertiaryContainer: Color(0xFF1E1B4B),
        onTertiaryContainer: _white,
        error: _red500,
        onError: _white,
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFCA5A5),
        outline: _zinc800,
        outlineVariant: Color(0xFF3F3F46),
        surfaceContainerHighest: _zinc900,
        surfaceContainerHigh: _zinc900,
        surfaceContainer: _zinc900,
        surfaceContainerLow: _black,
        surfaceContainerLowest: _black,
        surfaceBright: _zinc900,
        surfaceDim: _black,
        inverseSurface: _white,
        onInverseSurface: _black,
        inversePrimary: _indigo500,
        shadow: Colors.transparent,
        scrim: Color(0x80000000),
      ),
      textTheme: _buildTextTheme(ThemeData.dark().textTheme, _white, _zinc400),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _black,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: _zinc900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _zinc800, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: _zinc800,
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _black,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _indigo500.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _indigo500, size: 24);
          }
          return const IconThemeData(color: _zinc400, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          const base = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: _indigo500);
          }
          return base.copyWith(color: _zinc400);
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _white;
          return _zinc400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _indigo500;
          return _zinc800;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _zinc900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _zinc800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _zinc800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _indigo500, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _zinc400),
        hintStyle: const TextStyle(color: _zinc400),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _white,
          foregroundColor: _black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _white,
          side: const BorderSide(color: _zinc800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // MATERIAL FALLBACK — LIGHT
  // ════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _indigo500,
        brightness: Brightness.light,
        surface: _lightBg,
        onSurface: _lightText,
      ),
      textTheme: _buildTextTheme(ThemeData.light().textTheme, _lightText, _lightMuted),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _lightBg,
        foregroundColor: _lightText,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: _lightBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: _lightBorder,
        thickness: 1,
        space: 0,
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // HELPER: Inter typography — Apple HIG sizing
  // ════════════════════════════════════════════════════════
  static TextTheme _buildTextTheme(TextTheme base, Color body, Color caption) {
    return GoogleFonts.interTextTheme(base).copyWith(
      // Large Title 34pt (Apple HIG)
      displayLarge: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700, color: body, letterSpacing: -0.5),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: body, letterSpacing: -0.3),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: body),
      headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: body),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: body),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: body),
      // Inline Title 17pt Semibold (Apple HIG)
      titleLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: body),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: body),
      titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: body),
      // Body 17pt Regular (Apple HIG)
      bodyLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, color: body),
      bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: body),
      // Caption 13pt (Apple HIG: 60–70% opacity → Zinc 400)
      bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: caption),
      labelLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: body),
      labelMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: caption),
      // Tab Label 11pt (Apple HIG)
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: caption, letterSpacing: 0),
    );
  }
}
