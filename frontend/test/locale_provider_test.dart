import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/providers/locale_provider.dart';

void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('no saved choice means not chosen yet (null)', () async {
    final notifier = LocaleNotifier(await prefsWith({}));
    expect(notifier.state, isNull);
  });

  test('a saved supported code is restored', () async {
    final notifier = LocaleNotifier(await prefsWith({'app_locale': 'hi'}));
    expect(notifier.state, const Locale('hi'));
  });

  test('an unsupported saved code is treated as not chosen', () async {
    final notifier = LocaleNotifier(await prefsWith({'app_locale': 'fr'}));
    expect(notifier.state, isNull);
  });

  test('setLocale saves and updates state; unsupported locale is ignored',
      () async {
    final prefs = await prefsWith({});
    final notifier = LocaleNotifier(prefs);

    await notifier.setLocale(const Locale('hi'));
    expect(notifier.state, const Locale('hi'));
    expect(prefs.getString('app_locale'), 'hi');

    await notifier.setLocale(const Locale('fr'));
    expect(notifier.state, const Locale('hi'));
    expect(prefs.getString('app_locale'), 'hi');
  });
}
