import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/l10n/app_localizations.dart';
import 'support/screen_registry.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';
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

const _arrow = ' ← ';

/// Pumps [screen] on a narrow phone in [locale] and returns every layout
/// overflow reported while building it, as "message  [widget ancestor chain]".
/// The chain identifies the widget, so English and Hindi can be compared even
/// though the overflow size differs.
Future<List<String>> _overflowsFor(
  WidgetTester tester,
  Widget screen,
  Locale locale,
  double width,
  double textScale,
) async {
  // Tall so lazily built lists are all laid out; width is what overflows.
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'app_locale': locale.languageCode});
  final prefs = await SharedPreferences.getInstance();

  final overflows = <String>[];
  final oldOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    // Sub-2px overflows are rounding noise, not clipped text.
    final amount = RegExp(r'overflowed by ([\d.]+) pixels').firstMatch(msg);
    final pixels = double.tryParse(amount?.group(1) ?? '') ?? 99;
    if (msg.contains('overflowed') && pixels < 2) return;
    if (msg.contains('overflowed')) {
      final lines = [
        if (details.exception is FlutterError)
          ...(details.exception as FlutterError)
              .diagnostics
              .map((n) => n.toDescription()),
        ...?details.informationCollector?.call().map((n) => n.toDescription()),
      ];
      final chain = lines.firstWhere((l) => l.contains(_arrow),
          orElse: () => 'unknown widget');
      overflows.add('${msg.split('\n').first}  [$chain]');
    } else {
      oldOnError?.call(details);
    }
  };

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authProvider.overrideWith((ref) => _FakeAuth()),
      locationTrackingProvider.overrideWith((ref) => _FakeTracking()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: screen),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  // Restore before any expect(), or the test framework complains.
  FlutterError.onError = oldOnError;
  return overflows;
}

/// The widget chain without run-specific ids such as "#4312a".
String _chainOf(String overflow) => overflow
    .substring(overflow.indexOf('['))
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'#[0-9a-f]{5}'), '#');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The screens come from test/support/screen_registry.dart. Add a new screen
  // there (or to its skip list); screen_guard_test.dart fails until you do.
  final screens = coveredScreens;

  // A small phone (360 wide), and the same phone with the system font at 130%.
  const scales = <double>[1.0, 1.3];

  for (final entry in screens.entries) {
    for (final scale in scales) {
      testWidgets('${entry.key} has no new overflow in Hindi (360 wide, text x$scale)',
          (tester) async {
        final en = await _overflowsFor(
            tester, entry.value(), const Locale('en'), 360, scale);
        await tester.pumpWidget(const SizedBox());
        final hi = await _overflowsFor(
            tester, entry.value(), const Locale('hi'), 360, scale);

        // Overflows that already exist in English are not this test's concern:
        // fail only on widgets that overflow in Hindi but not in English.
        // Count per widget: Hindi may not overflow in more places than English.
        final enCount = <String, int>{};
        for (final o in en) {
          enCount.update(_chainOf(o), (n) => n + 1, ifAbsent: () => 1);
        }
        final fresh = <String>[];
        for (final o in hi) {
          final left = enCount[_chainOf(o)] ?? 0;
          if (left > 0) {
            enCount[_chainOf(o)] = left - 1;
          } else {
            fresh.add(o);
          }
        }
        expect(fresh, isEmpty,
            reason: 'New overflow in Hindi (English has ${en.length}):\n'
                '${fresh.join('\n')}');
      });
    }
  }
}
