import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fleet Management Theme - Orange Primary Design System (Stitch Design)
class AppTheme {
  // ==================== PRIMARY ORANGE SHADES ====================
  static const Color primaryBlue = Color(0xFFEC5B13);        // Main brand orange (legacy name kept)
  static const Color primaryBlueDark = Color(0xFFD14A0A);    // Darker orange variant
  static const Color primaryBlueLight = Color(0xFFF07540);   // Lighter orange variant
  static const Color primaryBlueExtraLight = Color(0xFFF5A07A); // Extra light orange

  // ==================== ACCENT COLORS ====================
  static const Color accentCyan = Color(0xFF06B6D4);         // For highlights & CTAs
  static const Color accentSky = Color(0xFF0EA5E9);          // For status indicators
  static const Color accentIndigo = Color(0xFF6366F1);       // For special actions

  // ==================== BACKGROUND & SURFACES ====================
  static const Color bgPrimary = Color(0xFFF8F6F6);          // Main background (warm white)
  static const Color bgSecondary = Color(0xFFFFFFFF);        // Cards/surfaces
  static const Color bgTertiary = Color(0xFFF1F0F0);         // Secondary surfaces

  // ==================== TEXT COLORS ====================
  static const Color textPrimary = Color(0xFF0F172A);        // Main text (slate-900)
  static const Color textSecondary = Color(0xFF475569);      // Secondary text (slate-600)
  static const Color textTertiary = Color(0xFF94A3B8);       // Muted text (slate-400)

  // ==================== STATUS COLORS ====================
  static const Color statusActive = Color(0xFF10B981);       // Green - Active/Online
  static const Color statusWarning = Color(0xFFF59E0B);      // Amber - Warning
  static const Color statusError = Color(0xFFEF4444);        // Red - Error/Offline
  static const Color statusInfo = Color(0xFF3B82F6);         // Blue - Info
  static const Color statusIdle = Color(0xFF6B7280);         // Gray - Idle

  // Legacy compatibility colors
  static const Color primaryColor = primaryBlue;
  static const Color primaryLight = primaryBlueLight;
  static const Color primaryDark = primaryBlueDark;
  static const Color secondaryColor = accentCyan;
  static const Color successColor = statusActive;
  static const Color errorColor = statusError;
  static const Color warningColor = statusWarning;
  static const Color infoColor = statusInfo;
  static const Color surfaceLight = bgPrimary;
  static const Color surfaceDark = Color(0xFF221610);

  // ==================== GRADIENT DEFINITIONS ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark, Color(0xFFBF4209)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, Color(0xFF0891B2), Color(0xFF0E7490)],
  );

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentSky, Color(0xFF0284C7), Color(0xFF1E40AF)],
  );

  static const LinearGradient subtleBlueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF7F4), Color(0xFFFFFFFF)],
  );

  // ==================== LIGHT THEME ====================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,

    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFE4D6),
      onPrimaryContainer: primaryBlueDark,

      secondary: accentCyan,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFCFFAFE),
      onSecondaryContainer: const Color(0xFF164E63),

      tertiary: accentSky,
      onTertiary: Colors.white,

      error: statusError,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF991B1B),

      surface: bgSecondary,
      onSurface: textPrimary,

      surfaceContainerHighest: bgSecondary,
      outline: const Color(0xFFE2E0E0),
      outlineVariant: const Color(0xFFF1F0F0),

      shadow: Colors.black12,
    ),

    scaffoldBackgroundColor: bgPrimary,

    // ==================== APP BAR ====================
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: bgSecondary,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    ),

    // ==================== CARD THEME ====================
    cardTheme: CardThemeData(
      elevation: 0,
      color: bgSecondary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFFE2E0E0).withOpacity(0.6),
          width: 1,
        ),
      ),
    ),

    // ==================== ELEVATED BUTTON ====================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: primaryBlue.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // ==================== OUTLINED BUTTON ====================
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // ==================== TEXT BUTTON ====================
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    // ==================== INPUT DECORATION ====================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E0E0), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E0E0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: statusError, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: statusError, width: 2),
      ),

      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: primaryBlue,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: textTertiary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
      errorStyle: const TextStyle(
        color: statusError,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ==================== FLOATING ACTION BUTTON ====================
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // ==================== CHIP THEME ====================
    chipTheme: ChipThemeData(
      backgroundColor: bgTertiary,
      selectedColor: primaryBlue.withOpacity(0.15),
      labelStyle: const TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // ==================== DIVIDER THEME ====================
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E0E0),
      thickness: 1,
      space: 1,
    ),

    // ==================== PROGRESS INDICATOR ====================
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryBlue,
      linearTrackColor: Color(0xFFE2E0E0),
      circularTrackColor: Color(0xFFE2E0E0),
    ),

    // ==================== TYPOGRAPHY ====================
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: textPrimary, height: 1.12),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, color: textPrimary, height: 1.16),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, color: textPrimary, height: 1.22),

      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary, height: 1.25),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary, height: 1.29),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary, height: 1.33),

      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary, height: 1.27),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, color: textPrimary, height: 1.5),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: textPrimary, height: 1.43),

      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: textPrimary, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: textSecondary, height: 1.43),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: textTertiary, height: 1.33),

      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: textPrimary, height: 1.43),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: textPrimary, height: 1.33),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: textSecondary, height: 1.45),
    ),
  );

  // ==================== DARK THEME ====================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryBlueLight,

    colorScheme: ColorScheme.dark(
      primary: primaryBlueLight,
      onPrimary: Colors.white,
      primaryContainer: primaryBlueDark,
      onPrimaryContainer: const Color(0xFFFFE4D6),

      secondary: accentCyan,
      onSecondary: const Color(0xFF164E63),

      tertiary: accentSky,

      error: statusError,
      onError: Colors.white,

      surface: const Color(0xFF221610),
      onSurface: Colors.white,

      surfaceContainerHighest: const Color(0xFF2C1F15),
      outline: const Color(0xFF4A3728),

      shadow: Colors.black.withOpacity(0.3),
    ),

    scaffoldBackgroundColor: surfaceDark,

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Color(0xFF221610),
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF2C1F15),
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF4A3728).withOpacity(0.3),
          width: 1,
        ),
      ),
    ),
  );
}
