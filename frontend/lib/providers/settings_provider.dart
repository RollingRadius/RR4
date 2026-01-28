import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Settings Model
class AppSettings {
  // Notifications
  final bool notificationsEnabled;
  final bool tripNotifications;
  final bool driverNotifications;
  final bool vehicleNotifications;

  // Location & Tracking
  final bool gpsTrackingEnabled;
  final bool backgroundTracking;
  final int locationUpdateInterval; // in seconds

  // Display
  final String themeMode; // 'system', 'light', 'dark'
  final bool compactView;

  // Data & Storage
  final bool autoSync;
  final bool offlineMode;

  // Privacy & Security
  final bool biometricLock;
  final bool shareAnalytics;

  AppSettings({
    this.notificationsEnabled = true,
    this.tripNotifications = true,
    this.driverNotifications = true,
    this.vehicleNotifications = true,
    this.gpsTrackingEnabled = true,
    this.backgroundTracking = false,
    this.locationUpdateInterval = 15,
    this.themeMode = 'system',
    this.compactView = false,
    this.autoSync = true,
    this.offlineMode = true,
    this.biometricLock = false,
    this.shareAnalytics = true,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? tripNotifications,
    bool? driverNotifications,
    bool? vehicleNotifications,
    bool? gpsTrackingEnabled,
    bool? backgroundTracking,
    int? locationUpdateInterval,
    String? themeMode,
    bool? compactView,
    bool? autoSync,
    bool? offlineMode,
    bool? biometricLock,
    bool? shareAnalytics,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      tripNotifications: tripNotifications ?? this.tripNotifications,
      driverNotifications: driverNotifications ?? this.driverNotifications,
      vehicleNotifications: vehicleNotifications ?? this.vehicleNotifications,
      gpsTrackingEnabled: gpsTrackingEnabled ?? this.gpsTrackingEnabled,
      backgroundTracking: backgroundTracking ?? this.backgroundTracking,
      locationUpdateInterval: locationUpdateInterval ?? this.locationUpdateInterval,
      themeMode: themeMode ?? this.themeMode,
      compactView: compactView ?? this.compactView,
      autoSync: autoSync ?? this.autoSync,
      offlineMode: offlineMode ?? this.offlineMode,
      biometricLock: biometricLock ?? this.biometricLock,
      shareAnalytics: shareAnalytics ?? this.shareAnalytics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'tripNotifications': tripNotifications,
      'driverNotifications': driverNotifications,
      'vehicleNotifications': vehicleNotifications,
      'gpsTrackingEnabled': gpsTrackingEnabled,
      'backgroundTracking': backgroundTracking,
      'locationUpdateInterval': locationUpdateInterval,
      'themeMode': themeMode,
      'compactView': compactView,
      'autoSync': autoSync,
      'offlineMode': offlineMode,
      'biometricLock': biometricLock,
      'shareAnalytics': shareAnalytics,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      tripNotifications: json['tripNotifications'] ?? true,
      driverNotifications: json['driverNotifications'] ?? true,
      vehicleNotifications: json['vehicleNotifications'] ?? true,
      gpsTrackingEnabled: json['gpsTrackingEnabled'] ?? true,
      backgroundTracking: json['backgroundTracking'] ?? false,
      locationUpdateInterval: json['locationUpdateInterval'] ?? 15,
      themeMode: json['themeMode'] ?? 'system',
      compactView: json['compactView'] ?? false,
      autoSync: json['autoSync'] ?? true,
      offlineMode: json['offlineMode'] ?? true,
      biometricLock: json['biometricLock'] ?? false,
      shareAnalytics: json['shareAnalytics'] ?? true,
    );
  }
}

/// Settings State
class SettingsState {
  final bool isLoading;
  final AppSettings settings;
  final String? error;

  SettingsState({
    this.isLoading = false,
    required this.settings,
    this.error,
  });

  SettingsState copyWith({
    bool? isLoading,
    AppSettings? settings,
    String? error,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      error: error,
    );
  }
}

/// Settings Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _settingsKey = 'app_settings';
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(SettingsState(settings: AppSettings())) {
    _loadSettings();
  }

  /// Load settings from local storage
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final settingsJson = _prefs.getString(_settingsKey);

      if (settingsJson != null) {
        // Parse JSON
        final settingsMap = <String, dynamic>{};
        final pairs = settingsJson.split('&');
        for (final pair in pairs) {
          final keyValue = pair.split('=');
          if (keyValue.length == 2) {
            final key = keyValue[0];
            final value = keyValue[1];

            // Parse value based on type
            if (value == 'true' || value == 'false') {
              settingsMap[key] = value == 'true';
            } else if (int.tryParse(value) != null) {
              settingsMap[key] = int.parse(value);
            } else {
              settingsMap[key] = value;
            }
          }
        }

        final settings = AppSettings.fromJson(settingsMap);
        state = state.copyWith(
          isLoading: false,
          settings: settings,
        );
      } else {
        // No saved settings, use defaults
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Save settings to local storage
  Future<void> _saveSettings() async {
    try {
      final settingsMap = state.settings.toJson();

      // Convert to simple string format
      final pairs = settingsMap.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('&');

      await _prefs.setString(_settingsKey, pairs);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update a single setting
  Future<void> updateSetting(String key, dynamic value) async {
    AppSettings updatedSettings;

    switch (key) {
      case 'notificationsEnabled':
        updatedSettings = state.settings.copyWith(notificationsEnabled: value as bool);
        break;
      case 'tripNotifications':
        updatedSettings = state.settings.copyWith(tripNotifications: value as bool);
        break;
      case 'driverNotifications':
        updatedSettings = state.settings.copyWith(driverNotifications: value as bool);
        break;
      case 'vehicleNotifications':
        updatedSettings = state.settings.copyWith(vehicleNotifications: value as bool);
        break;
      case 'gpsTrackingEnabled':
        updatedSettings = state.settings.copyWith(gpsTrackingEnabled: value as bool);
        break;
      case 'backgroundTracking':
        updatedSettings = state.settings.copyWith(backgroundTracking: value as bool);
        break;
      case 'locationUpdateInterval':
        updatedSettings = state.settings.copyWith(locationUpdateInterval: value as int);
        break;
      case 'themeMode':
        updatedSettings = state.settings.copyWith(themeMode: value as String);
        break;
      case 'compactView':
        updatedSettings = state.settings.copyWith(compactView: value as bool);
        break;
      case 'autoSync':
        updatedSettings = state.settings.copyWith(autoSync: value as bool);
        break;
      case 'offlineMode':
        updatedSettings = state.settings.copyWith(offlineMode: value as bool);
        break;
      case 'biometricLock':
        updatedSettings = state.settings.copyWith(biometricLock: value as bool);
        break;
      case 'shareAnalytics':
        updatedSettings = state.settings.copyWith(shareAnalytics: value as bool);
        break;
      default:
        return; // Unknown key, do nothing
    }

    state = state.copyWith(settings: updatedSettings);
    await _saveSettings();
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    state = state.copyWith(settings: AppSettings());
    await _saveSettings();
  }

  /// Clear cache
  Future<void> clearCache() async {
    // TODO: Implement cache clearing logic
    // This would involve clearing any cached images, data, etc.
    await Future.delayed(const Duration(seconds: 1)); // Simulate clearing
  }
}

/// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

/// Settings Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
