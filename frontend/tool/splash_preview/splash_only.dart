// Dev-only: shows just the real splash widget, full screen, exactly as the app plays it.
// Click / tap anywhere to replay.
//   flutter run -d chrome -t tool/splash_preview/splash_only.dart
import 'package:flutter/material.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_animation.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_quality.dart';

void main() {
  // Always show full quality here (the real app steps down automatically on slow devices).
  SplashQualityMonitor.debugForcedTier = SplashTier.full;
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: _SplashOnly()));
}

class _SplashOnly extends StatefulWidget {
  const _SplashOnly();

  @override
  State<_SplashOnly> createState() => _SplashOnlyState();
}

class _SplashOnlyState extends State<_SplashOnly> {
  Key _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _key = UniqueKey()),
        child: SplashAnimation(key: _key, onStarted: (_) {}, onUnavailable: () {}),
      ),
    );
  }
}
