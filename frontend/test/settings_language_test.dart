import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/l10n/app_localizations.dart';
import 'package:fleet_management/presentation/screens/settings/settings_screen.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';
import 'package:fleet_management/providers/locale_provider.dart';
import 'package:fleet_management/providers/settings_provider.dart';

/// Stand-ins for providers that need real services (API, GPS).
class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(AuthState(isInitialized: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTracking extends StateNotifier<LocationTrackingState>
    implements LocationTrackingNotifier {
  _FakeTracking() : super(LocationTrackingState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Expected texts come from the ARB files, so rewording a string never breaks
/// this test and no Hindi is copied into it.
String _arbText(String file, String key) =>
    (jsonDecode(File('lib/l10n/$file').readAsStringSync())
        as Map<String, dynamic>)[key] as String;

class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeProvider) ?? const Locale('en'),
      supportedLocales: LocaleNotifier.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(body: SettingsScreen()),
    );
  }
}

void main() {
  testWidgets('picking हिंदी in Settings switches the screen to Hindi and saves it',
      (tester) async {
    // Tall screen so every Settings section is built without scrolling.
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();

    final enTitle = _arbText('app_en.arb', 'settingsLanguageTitle');
    final enSubtitle = _arbText('app_en.arb', 'settingsLanguageSubtitle');
    final hiTitle = _arbText('app_hi.arb', 'settingsLanguageTitle');
    final hiSubtitle = _arbText('app_hi.arb', 'settingsLanguageSubtitle');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authProvider.overrideWith((ref) => _FakeAuth()),
        locationTrackingProvider.overrideWith((ref) => _FakeTracking()),
      ],
      child: const _Harness(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500)); // sections fade in

    expect(find.text(enSubtitle), findsOneWidget, reason: 'starts in English');
    expect(find.text(hiSubtitle), findsNothing);

    await tester.tap(find.text(enSubtitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();

    expect(find.text(hiSubtitle), findsOneWidget, reason: 'now in Hindi');
    expect(find.text(enSubtitle), findsNothing);
    expect(find.text(hiTitle), findsWidgets);
    expect(prefs.getString('app_locale'), 'hi', reason: 'choice is saved');

    // And back to English.
    await tester.tap(find.text(hiSubtitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text(enSubtitle), findsOneWidget);
    expect(find.text(enTitle), findsWidgets);
    expect(prefs.getString('app_locale'), 'en');
  });
}
