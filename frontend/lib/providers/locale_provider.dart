import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/providers/settings_provider.dart';

/// The app language. `null` state means the user has not chosen yet — the
/// first-launch language dialog (shown after the splash) is what sets it.
class LocaleNotifier extends StateNotifier<Locale?> {
  static const _prefsKey = 'app_locale';
  static const supportedLocales = [Locale('en'), Locale('hi')];

  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(_load(_prefs));

  static Locale? _load(SharedPreferences prefs) {
    final code = prefs.getString(_prefsKey);
    for (final locale in supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    state = locale;
    await _prefs.setString(_prefsKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});
