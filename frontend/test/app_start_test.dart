import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/main.dart';
import 'package:fleet_management/presentation/screens/auth/login_screen.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/settings_provider.dart';

/// Stand-in for the real AuthNotifier (which needs API/storage services): a
/// logged-out user whose saved session check has already finished.
class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(AuthState(isInitialized: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Expected texts come from the ARB files, so rewording a string never breaks
/// this test and no Hindi is copied into it.
String _arbText(String file, String key) =>
    (jsonDecode(File('lib/l10n/$file').readAsStringSync())
        as Map<String, dynamic>)[key] as String;

/// Builds the whole app (real router, theme, splash, login) with only the
/// device services replaced. Firebase / FCM start-up lives in main(), not here.
Future<SharedPreferences> _pumpApp(
  WidgetTester tester,
  Map<String, Object> savedPrefs,
) async {
  SharedPreferences.setMockInitialValues(savedPrefs);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authProvider.overrideWith((ref) => _FakeAuth()),
    ],
    child: const FleetManagementApp(),
  ));
  // let the splash sprites decode (real async), then build the first frame
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  return prefs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app starts, plays the splash and shows the login screen',
      (tester) async {
    await _pumpApp(tester, {'app_locale': 'en'});
    expect(find.byType(LoginScreen), findsNothing, reason: 'splash comes first');

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(_arbText('app_en.arb', 'loginForgotPassword')),
        findsOneWidget);
  });

  testWidgets(
      'first launch: language is asked after the splash, and choosing हिंदी '
      'shows the login screen in Hindi', (tester) async {
    final prefs = await _pumpApp(tester, {});

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    expect(find.text('हिंदी'), findsOneWidget, reason: 'language dialog shows');
    expect(find.byType(LoginScreen), findsNothing);

    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue · जारी रखें'));   // the redesigned dialog: pick, then Continue

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(_arbText('app_hi.arb', 'loginForgotPassword')),
        findsOneWidget);
    expect(find.text(_arbText('app_en.arb', 'loginForgotPassword')),
        findsNothing);
    expect(prefs.getString('app_locale'), 'hi');
  });

  testWidgets(
      'first launch: closing the app without choosing a language asks again on the next open '
      '(user, 2026-11-21)', (tester) async {
    var prefs = await _pumpApp(tester, {});
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);

    // tries to get past without choosing: tap outside, Back
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Please choose a language · कृपया एक भाषा चुनें'), findsOneWidget);
    expect(prefs.getString('app_locale'), isNull, reason: 'nothing saved');

    // the app is closed and opened again with what the phone saved
    final saved = {for (final k in prefs.getKeys()) k: prefs.get(k)!};
    await tester.pumpWidget(const SizedBox());
    prefs = await _pumpApp(tester, saved);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget, reason: 'asked again');
    final checks = tester.widgetList<AnimatedOpacity>(
        find.ancestor(of: find.byIcon(Icons.check_circle_rounded), matching: find.byType(AnimatedOpacity)));
    expect(checks.every((o) => o.opacity == 0), isTrue, reason: 'nothing pre-selected');
    expect(find.byType(LoginScreen), findsNothing);
  });
}
