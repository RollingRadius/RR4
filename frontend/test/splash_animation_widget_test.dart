import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_animation.dart';

// Kept free of dart:io so it also runs on web:  flutter test --platform chrome test/splash_animation_widget_test.dart
// (the web renderer manages image/shader lifetimes differently from native, so this catches disposal bugs).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashAnimation widget', () {
    Future<void> settle(WidgetTester tester) async {
      // let the sprites decode (real async), then build the frame that follows
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }

    testWidgets('reports its start once with the full 1.8s minimum, then finishes on time', (tester) async {
      final started = <Duration>[];
      var unavailable = 0;
      await tester.pumpWidget(MaterialApp(
        home: SplashAnimation(onStarted: started.add, onUnavailable: () => unavailable++),
      ));
      await settle(tester);
      expect(started, [const Duration(milliseconds: 1800)]);
      expect(unavailable, 0);
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      // tear down cleanly (ticker + sprites disposed)
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects reduce-motion: shows the final logo and a short minimum time', (tester) async {
      final started = <Duration>[];
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: SplashAnimation(onStarted: started.add, onUnavailable: () {})),
      ));
      await settle(tester);
      expect(started, [const Duration(milliseconds: 600)]);
      expect(tester.takeException(), isNull);
    });
  });
}
