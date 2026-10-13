import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_animation.dart';
import 'package:fleet_management/presentation/screens/splash/splash_screen.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Stand-in for the real AuthNotifier (which needs API/storage services): just holds an AuthState.
class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth(super.state);

  void set(AuthState s) => state = s;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_FakeAuth> pumpSplash(WidgetTester tester, AuthState initial) async {
    final auth = _FakeAuth(initial);
    final router = GoRouter(initialLocation: '/splash', routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const Text('LOGIN_PAGE')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [authProvider.overrideWith((ref) => auth)],
      child: MaterialApp.router(routerConfig: router),
    ));
    // let the sprites decode (real async), then build the first animated frame
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    return auth;
  }

  testWidgets('the real splash screen plays the new animation (not the old logo fade)', (tester) async {
    await pumpSplash(tester, AuthState(isInitialized: false));
    expect(find.byType(SplashAnimation), findsOneWidget);
    expect(find.byType(Image), findsNothing, reason: 'the plain-logo fallback must not be showing');
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pump(const Duration(milliseconds: 2500)); // let timers finish so the test can end cleanly
  });

  testWidgets('holds the full 1.8s minimum, then goes to login when logged out', (tester) async {
    await pumpSplash(tester, AuthState(isInitialized: true));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('LOGIN_PAGE'), findsNothing, reason: 'still playing at 1.0s');
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('LOGIN_PAGE'), findsNothing, reason: 'still playing at 1.7s');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN_PAGE'), findsOneWidget, reason: 'after 1.8s with no session it goes to login');
  });

  testWidgets('never leaves early or guesses: waits for login status, then navigates', (tester) async {
    final auth = await pumpSplash(tester, AuthState(isInitialized: false));
    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text('LOGIN_PAGE'), findsNothing, reason: 'auth still restoring - must stay on the splash');
    auth.set(AuthState(isInitialized: true));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('LOGIN_PAGE'), findsOneWidget);
  });
}
