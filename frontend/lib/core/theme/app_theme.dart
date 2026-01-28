import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Application Theme Configuration - Material You Design
class AppTheme {
  // Primary Colors - Modern Blue Palette
  static const Color primaryColor = Color(0xFF1976D2); // Deep Blue
  static const Color primaryLight = Color(0xFF63A4FF);
  static const Color primaryDark = Color(0xFF004BA0);

  // Accent Colors
  static const Color secondaryColor = Color(0xFF26C6DA); // Cyan
  static const Color successColor = Color(0xFF66BB6A); // Green
  static const Color errorColor = Color(0xFFEF5350); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color infoColor = Color(0xFF42A5F5); // Light Blue

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1976D2), Color(0xFF1565C0), Color(0xFF0D47A1)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF26C6DA), Color(0xFF00ACC1), Color(0xFF00838F)],
  );

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF121212);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Light Theme - Modern Material You
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,

    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFBBDEFB),
      onPrimaryContainer: const Color(0xFF0D47A1),

      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB2EBF2),
      onSecondaryContainer: const Color(0xFF006064),

      tertiary: successColor,
      onTertiary: Colors.white,

      error: errorColor,
      onError: Colors.white,

      surface: surfaceLight,
      onSurface: textPrimary,

      surfaceContainerHighest: Colors.white,
      outline: const Color(0xFFE0E0E0),
      outlineVariant: const Color(0xFFF5F5F5),

      shadow: Colors.black.withOpacity(0.1),
    ),

    scaffoldBackgroundColor: const Color(0xFFF5F7FA),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    ),

    // Card Theme - Elevated with shadow
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFFE0E0E0).withOpacity(0.3),
          width: 1,
        ),
      ),
    ),

    // Elevated Button - Modern with gradient support
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
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

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
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

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
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

    // Input Decoration - Modern with subtle borders
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

      // Default border
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
      ),

      // Enabled border
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
      ),

      // Focused border
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),

      // Error border
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),

      // Focused error border
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),

      // Label style
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),

      // Floating label style
      floatingLabelStyle: const TextStyle(
        color: primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),

      // Hint style
      hintStyle: TextStyle(
        color: textHint,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),

      // Prefix icon style
      prefixIconColor: textSecondary,

      // Error style
      errorStyle: const TextStyle(
        color: errorColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF5F5F5),
      selectedColor: primaryColor.withOpacity(0.2),
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

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),

    // Typography
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: textPrimary),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, color: textPrimary),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, color: textPrimary),

      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary),

      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0, color: textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, color: textPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: textPrimary),

      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: textPrimary),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: textSecondary),

      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: textPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: textPrimary),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: textSecondary),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryLight,

    colorScheme: ColorScheme.dark(
      primary: primaryLight,
      onPrimary: const Color(0xFF0D47A1),
      primaryContainer: const Color(0xFF1565C0),
      onPrimaryContainer: const Color(0xFFBBDEFB),

      secondary: secondaryColor,
      onSecondary: const Color(0xFF006064),

      tertiary: successColor,

      error: errorColor,
      onError: Colors.white,

      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,

      surfaceContainerHighest: const Color(0xFF2C2C2C),
      outline: const Color(0xFF424242),

      shadow: Colors.black.withOpacity(0.3),
    ),

    scaffoldBackgroundColor: surfaceDark,

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E1E1E),
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF424242).withOpacity(0.3),
          width: 1,
        ),
      ),
    ),
  );
}
