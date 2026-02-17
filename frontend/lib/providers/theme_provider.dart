import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/data/models/branding_model.dart';
import 'package:fleet_management/data/services/branding_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/settings_provider.dart';

/// Theme State
class ThemeState {
  final ThemeData themeData;
  final OrganizationBranding? branding;
  final bool isLoading;
  final String? error;

  ThemeState({
    required this.themeData,
    this.branding,
    this.isLoading = false,
    this.error,
  });

  ThemeState copyWith({
    ThemeData? themeData,
    OrganizationBranding? branding,
    bool? isLoading,
    String? error,
  }) {
    return ThemeState(
      themeData: themeData ?? this.themeData,
      branding: branding ?? this.branding,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Theme Notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _brandingCacheKey = 'cached_branding';
  final BrandingApi _brandingApi;
  final SharedPreferences _prefs;

  ThemeNotifier(this._brandingApi, this._prefs)
      : super(ThemeState(themeData: AppTheme.lightTheme)) {
    _loadCachedBranding();
  }

  /// Load cached branding on initialization for instant theme
  Future<void> _loadCachedBranding() async {
    try {
      final cachedJson = _prefs.getString(_brandingCacheKey);
      if (cachedJson != null) {
        final brandingMap = json.decode(cachedJson) as Map<String, dynamic>;
        final branding = OrganizationBranding.fromJson(brandingMap);
        final theme = _applyBranding(branding);
        state = ThemeState(themeData: theme, branding: branding);
      }
    } catch (e) {
      // Cache corrupted or invalid, ignore and use default theme
      debugPrint('Error loading cached branding: $e');
    }
  }

  /// Load branding from API and apply to theme
  Future<void> loadBranding() async {
    state = state.copyWith(isLoading: true);

    try {
      final branding = await _brandingApi.getBranding();

      // Cache branding for instant load next time
      await _cacheBranding(branding);

      // Apply branding to theme
      final theme = _applyBranding(branding);

      state = ThemeState(
        themeData: theme,
        branding: branding,
        isLoading: false,
      );
    } catch (e) {
      // On error, keep current theme (cached or default)
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Error loading branding: $e');
    }
  }

  /// Apply branding colors to ThemeData
  ThemeData _applyBranding(OrganizationBranding branding) {
    final colors = branding.colors;

    // Parse hex colors to Flutter Color objects
    final primary = _parseHexColor(colors.primaryColor);
    final primaryDark = _parseHexColor(colors.primaryDark);
    final primaryLight = _parseHexColor(colors.primaryLight);
    final secondary = _parseHexColor(colors.secondaryColor);
    final accent = _parseHexColor(colors.accentColor);
    final bgPrimary = _parseHexColor(colors.backgroundPrimary);
    final bgSecondary = _parseHexColor(colors.backgroundSecondary);

    // Create custom ThemeData based on branding colors
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,

      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight.withOpacity(0.2),
        onPrimaryContainer: primaryDark,

        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondary.withOpacity(0.2),
        onSecondaryContainer: secondary,

        tertiary: accent,
        onTertiary: Colors.white,

        error: AppTheme.statusError,
        onError: Colors.white,
        errorContainer: const Color(0xFFFEE2E2),
        onErrorContainer: const Color(0xFF991B1B),

        surface: bgSecondary,
        onSurface: AppTheme.textPrimary,

        surfaceContainerHighest: bgSecondary,
        outline: const Color(0xFFE2E8F0),
        outlineVariant: const Color(0xFFF1F5F9),

        shadow: Colors.black.withOpacity(0.08),
      ),

      scaffoldBackgroundColor: bgPrimary,

      // App Bar with custom colors
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: bgSecondary,
        foregroundColor: AppTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        iconTheme: const IconThemeData(
          color: AppTheme.textPrimary,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: bgSecondary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.05),
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFE2E8F0).withOpacity(0.6),
            width: 1,
          ),
        ),
      ),

      // Elevated Button with custom primary color
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primary.withOpacity(0.3),
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

      // Outlined Button with custom primary color
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
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

      // Text Button with custom primary color
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
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

      // Input Decoration with custom primary color
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.statusError, width: 1.5),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.statusError, width: 2),
        ),

        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),

        floatingLabelStyle: TextStyle(
          color: primary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),

        hintStyle: const TextStyle(
          color: AppTheme.textTertiary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),

        prefixIconColor: AppTheme.textSecondary,
        suffixIconColor: AppTheme.textSecondary,

        errorStyle: const TextStyle(
          color: AppTheme.statusError,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Floating Action Button with custom primary color
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: primary.withOpacity(0.15),
        labelStyle: const TextStyle(
          color: AppTheme.textPrimary,
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
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator with custom primary color
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: const Color(0xFFE2E8F0),
        circularTrackColor: const Color(0xFFE2E8F0),
      ),

      // Typography (reuse AppTheme's text theme)
      textTheme: AppTheme.lightTheme.textTheme,
    );
  }

  /// Parse hex color string to Color object
  Color _parseHexColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      debugPrint('Error parsing hex color $hexColor: $e');
      return AppTheme.primaryBlue; // Fallback to default
    }
  }

  /// Cache branding in SharedPreferences
  Future<void> _cacheBranding(OrganizationBranding branding) async {
    try {
      final brandingJson = json.encode(branding.toJson());
      await _prefs.setString(_brandingCacheKey, brandingJson);
    } catch (e) {
      debugPrint('Error caching branding: $e');
    }
  }

  /// Clear branding and reset to default theme (on logout)
  Future<void> clearBranding() async {
    await _prefs.remove(_brandingCacheKey);
    state = ThemeState(themeData: AppTheme.lightTheme);
  }
}

/// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final brandingApi = BrandingApi(apiService);
  return ThemeNotifier(brandingApi, prefs);
});
