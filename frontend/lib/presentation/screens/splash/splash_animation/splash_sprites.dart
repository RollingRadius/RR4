import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// The pre-baked sprites the splash animation draws (see tool/splash_bake/bake.py).
/// Decoded once; the animation only transforms and draws them.
class SplashSprites {
  SplashSprites._({
    required this.tyreA,
    required this.tyreB,
    required this.caliper,
    required this.highlights,
    required this.tread,
    required this.smoke,
    required this.wordmark,
  });

  /// Tyre sprites are 512px covering 208 art units (the tyre's own radius is 100 units).
  static const double tyreUnits = 208;
  static const double treadWidthPx = 256, treadHeightPx = 1440; // tread: 72 units wide x 360 degrees

  final ui.Image tyreA, tyreB, caliper, highlights, tread, smoke, wordmark;

  static const String _base = 'assest/splash/';

  static Future<ui.Image> _load(String name) async {
    final data = await rootBundle.load('$_base$name.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static Future<SplashSprites> load() async {
    Object? failure;
    StackTrace? failureTrace;
    Future<ui.Image?> safe(String name) => _load(name).then<ui.Image?>((v) => v, onError: (Object e, StackTrace st) {
          failure ??= e;
          failureTrace ??= st;
          return null;
        });
    final loaded = await Future.wait([
      safe('tyre_a'),
      safe('tyre_b'),
      safe('tyre_caliper'),
      safe('tyre_hi'),
      safe('tread'),
      safe('smoke'),
      safe('wordmark'),
    ]);
    if (failure != null) {
      // don't leak the ones that did decode
      for (final img in loaded) {
        img?.dispose();
      }
      Error.throwWithStackTrace(failure!, failureTrace ?? StackTrace.current);
    }
    final r = loaded.cast<ui.Image>();
    return SplashSprites._(
      tyreA: r[0],
      tyreB: r[1],
      caliper: r[2],
      highlights: r[3],
      tread: r[4],
      smoke: r[5],
      wordmark: r[6],
    );
  }

  void dispose() {
    tyreA.dispose();
    tyreB.dispose();
    caliper.dispose();
    highlights.dispose();
    tread.dispose();
    smoke.dispose();
    wordmark.dispose();
  }
}
