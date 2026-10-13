import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_logo_geometry.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_painter.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_quality.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_sprites.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_timeline.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_trails.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashTimeline', () {
    final tl = SplashTimeline();
    final f = SplashFrame();

    test('tyre holds in place until 333ms, then runs up the road', () {
      tl.frame(0, f, 640);
      final y0 = f.tyreY;
      tl.frame(332, f, 640);
      expect(f.tyreY, closeTo(y0, 0.01));
      tl.frame(450, f, 640);
      expect(f.tyreY, lessThan(y0 - 20));
    });

    test('tyre ends at the logo wheel position at the same scale', () {
      tl.frame(SplashTiming.swap, f, 640);
      expect(f.tyreX, closeTo(SplashLayout.finalWheelX, 0.01));
      expect(f.tyreY, closeTo(SplashLayout.finalWheelY, 0.01));
      expect(f.tyreScale, closeTo(SplashLayout.finalScale, 0.0001));
      expect(f.wheelVisible, isTrue);
      expect(f.tyreVisible, isFalse);
    });

    test('perspective road has merged into the logo road by 1039ms', () {
      tl.frame(1038, f, 640);
      expect(f.roadVisible, isTrue);
      tl.frame(1039, f, 640);
      expect(f.roadVisible, isFalse);
      expect(f.phi, closeTo(0, 1e-9));
    });

    test('wordmark starts at 1042ms, is fully in at 1600ms, then the logo holds until 1800ms', () {
      tl.frame(1041, f, 640);
      expect(f.wordAlpha, 0);
      tl.frame(1100, f, 640);
      expect(f.wordAlpha, greaterThan(0));
      tl.frame(1500, f, 640);
      expect(f.wordAlpha, inExclusiveRange(0, 1));
      tl.frame(1600, f, 640);
      expect(f.wordAlpha, closeTo(1, 1e-9));
      tl.frame(1800, f, 640);
      expect(f.wordAlpha, closeTo(1, 1e-9));
      expect(SplashTiming.totalMs, 1800);
    });

    test('animation and logo timings are unchanged by the longer splash', () {
      expect(SplashTiming.smokeStart, 50);
      expect(SplashTiming.smokeEnd, 830);
      expect(SplashTiming.burnEnd, 333);
      expect(SplashTiming.rollEnd, 700);
      expect(SplashTiming.jumpEnd, 950);
      expect(SplashTiming.swap, 1010);
      expect(SplashTiming.roadEnd, 1039);
    });

    test('pure rear view (90deg) while running straight; the side turns into view once the road curves (~580ms)', () {
      final sc = TyrePose();
      for (final t in [0.0, 200, 333, 450, 570, 575]) {
        expect(tl.thetaAt(t.toDouble(), sc), 90, reason: 'tread only, no rim, at t=$t');
      }
      expect(tl.thetaAt(600, sc), lessThan(90));
      expect(tl.thetaAt(650, sc), lessThan(tl.thetaAt(600, sc)), reason: 'keeps tilting through the curve');
      expect(tl.thetaAt(699.9, sc), closeTo(31, 0.5), reason: 'same end angle as before, so the hop is unchanged');
      expect(tl.thetaAt(SplashTiming.rollEnd, sc), closeTo(31, 0.01));
      var prev = 91.0;
      for (var t = 0.0; t <= 700; t += 1) {
        final th = tl.thetaAt(t, sc);
        expect(th, lessThanOrEqualTo(prev), reason: 'angle never jumps back up at t=$t');
        expect(prev - th, lessThan(2), reason: 'no sudden pop at t=$t');
        prev = th;
      }
    });

    test('the finished logo is static during the final hold (1600-1800ms)', () {
      final a = SplashFrame(), b = SplashFrame();
      tl.frame(1600, a, 640);
      tl.frame(1800, b, 640);
      expect([b.tyreVisible, b.wheelVisible, b.roadVisible, b.wordAlpha], [a.tyreVisible, a.wheelVisible, a.roadVisible, a.wordAlpha]);
    });

    test('smoke starts at 50ms and is gone by 830ms', () {
      final buf = SmokeBuffer();
      expect(tl.smoke(49, buf), 0);
      expect(tl.smoke(60, buf), greaterThan(0));
      expect(tl.smoke(829.9, buf), lessThanOrEqualTo(1));
      expect(tl.smoke(830, buf), 0);
      expect(tl.smoke(1200, buf), 0);
    });

    test('smoke never overflows its buffer', () {
      final buf = SmokeBuffer();
      for (var t = 0.0; t <= 1800; t += 5) {
        expect(tl.smoke(t, buf), lessThanOrEqualTo(SmokeBuffer.capacity));
      }
    });

    test('wheel spin per frame stays below the strobing limit (60fps)', () {
      var worst = 0.0;
      for (var t = 1.0; t <= 1800; t += 1000 / 60) {
        worst = [worst, ((tl.rotAt(t) - tl.rotAt(t - 1000 / 60)) * 180 / 3.14159265).abs()].reduce((a, b) => a > b ? a : b);
      }
      expect(worst, lessThan(10), reason: 'tread block pitch is 20deg; staying under half of it avoids wagon-wheel strobing');
    });
  });

  group('SplashQualityMonitor', () {
    test('tier ladder only goes down and ends at light', () {
      var t = SplashTier.full;
      final seen = <SplashTier>[t];
      while (t.next != null) {
        t = t.next!;
        seen.add(t);
      }
      expect(seen, [SplashTier.full, SplashTier.medium, SplashTier.light]);
    });
  });

  group('SplashTrails (tied to the real tyre motion)', () {
    final tl = SplashTimeline();
    final tr = SplashTrails(tl);

    test('left streaks are near-black and sit on the left, right streaks are blue and sit on the right', () {
      expect(tr.streaks, hasLength(SplashTrails.count));
      final left = tr.streaks.where((s) => s.left), right = tr.streaks.where((s) => !s.left);
      expect(left, isNotEmpty);
      expect(right, isNotEmpty);
      expect(left.every((s) => s.lateral < 0), isTrue);
      expect(right.every((s) => s.lateral > 0), isTrue);
    });

    test('there are both thick main streaks and thin hairlines, on both sides', () {
      final main = tr.streaks.where((s) => !s.hairline), hair = tr.streaks.where((s) => s.hairline);
      expect(main, hasLength(SplashTrails.mainCount));
      expect(hair, hasLength(SplashTrails.hairCount));
      expect(hair.every((s) => s.thickness < main.map((m) => m.thickness).reduce(math.min)), isTrue);
      for (final group in [main, hair]) {
        expect(group.any((s) => s.left), isTrue);
        expect(group.any((s) => !s.left), isTrue);
      }
    });

    test('no trails while the tyre has not started to move (burn-out), none once it reaches the curve', () {
      for (final t in <double>[0, 100, 300, SplashTiming.burnEnd]) {
        expect(tr.build(t), isNull, reason: 'tyre is standing still at t=$t');
      }
      expect(tr.build(SplashTiming.rollEnd), isNull);
      expect(tr.build(900), isNull);
    });

    test('every streak finishes before the tyre reaches the curve', () {
      for (final st in tr.streaks) {
        expect(st.spawnDist + st.span, lessThan(tl.straightDistance));
        expect(st.spawnDist, greaterThan(0));
        expect([st.lateral, st.height, st.length, st.thickness, st.bend, st.span].every((v) => v.isFinite), isTrue);
      }
    });

    test('a streak stretches exactly as far as the tyre has receded, and not at all when the tyre is still', () {
      final st = tr.streaks.firstWhere((s) => !s.hairline);
      expect(tr.reach(st, st.spawnDist), 0);
      expect(tr.reach(st, st.spawnDist - 5), 0);
      var prev = 0.0;
      for (var d = st.spawnDist; d <= st.spawnDist + st.span; d += 1) {
        final r = tr.reach(st, d);
        expect(r, greaterThanOrEqualTo(prev), reason: 'never shrinks as the tyre moves on');
        expect(r, lessThanOrEqualTo(st.fullLength + 1e-9));
        prev = r;
      }
      final recede = 1 / tl.scaleAtDistance(st.spawnDist + 20) - 1 / tl.scaleAtDistance(st.spawnDist);
      expect(tr.reach(st, st.spawnDist + 20), closeTo(math.min(recede * SplashTrails.stretchGain, st.fullLength), 1e-9));
    });

    test('while the tyre is faster, trails grow faster (matches the tyre speed profile)', () {
      double reachSum(double t) {
        final d = tl.dist(t);
        return tr.streaks.fold<double>(0, (a, s) => a + tr.reach(s, d));
      }
      final slowGrowth = reachSum(380) - reachSum(350); // tyre still easing up to speed
      final fastGrowth = reachSum(530) - reachSum(500); // tyre at peak speed
      expect(fastGrowth, greaterThan(slowGrowth * 1.5));
    });

    test('trails are visible while the tyre runs on the straight and never produce bad numbers', () {
      var sawTrails = false;
      for (var t = 330.0; t <= 600; t += 1) {
        final v = tr.build(t);
        if (v != null) {
          sawTrails = true;
          v.dispose();
        }
      }
      expect(sawTrails, isTrue);
    });
  });

  group('SplashQualityMonitor policy', () {
    test('an adaptive monitor steps down when frames run slow (QA / tools)', () {
      final m = SplashQualityMonitor(initial: SplashTier.full);
      for (var i = 0; i < 30; i++) {
        m.report(40);
      }
      expect(m.tier, isNot(SplashTier.full));
    });

    test('the shipped monitor (adaptive: false) always stays at full quality, however slow the frames are', () {
      final m = SplashQualityMonitor(adaptive: false);
      for (var i = 0; i < 200; i++) {
        m.report(i.isEven ? 200 : 60); // terrible frames
      }
      expect(m.tier, SplashTier.full);
      m.attach(); // must be a no-op
      m.detach();
      expect(m.tier, SplashTier.full);
    });
  });

  group('SplashLogoGeometry', () {
    test('the sharp tip of the arch is covered by the wheel (no hairline of white between them)', () {
      final g = SplashLogoGeometry();
      final d = (g.tip - SplashLogoGeometry.wheelCenter).distance;
      expect(d, lessThan(SplashLogoGeometry.wheelRadius), reason: 'tip must sit inside the wheel, by $d vs radius ${SplashLogoGeometry.wheelRadius}');
    });

    test('during the landing squash the tyre keeps covering the arch tip (no flash of white)', () {
      final g = SplashLogoGeometry();
      final tl = SplashTimeline();
      final f = SplashFrame();
      final tipX = SplashLayout.logoTx + g.tip.dx * SplashLayout.logoScale;
      final tipY = SplashLayout.logoTy + g.tip.dy * SplashLayout.logoScale;
      for (var t = SplashTiming.jumpEnd; t < SplashTiming.swap; t += 2) {
        tl.frame(t, f, 640);
        final r = 100 * f.tyreScale;
        final nx = (tipX - f.tyreX) / (r * f.squashX), ny = (tipY - f.tyreY) / (r * f.squashY);
        expect(nx * nx + ny * ny, lessThan(1), reason: 'tip uncovered at t=$t');
      }
    });

    test('the tyre lands exactly on the logo wheel, at the same size', () {
      const w = SplashLogoGeometry.wheelCenter;
      expect(SplashLayout.finalWheelX, closeTo(SplashLayout.logoTx + w.dx * SplashLayout.logoScale, .15));
      expect(SplashLayout.finalWheelY, closeTo(SplashLayout.logoTy + w.dy * SplashLayout.logoScale, .15));
      expect(SplashLayout.finalScale * 100, closeTo(SplashLogoGeometry.wheelRadius * SplashLayout.logoScale, .05));
    });

    test('dashes at phi=0 are the final logo pattern and a fractional phi shifts them up the road', () {
      final g = SplashLogoGeometry();
      final a = g.dashes(0).getBounds();
      final b = g.dashes(0.4).getBounds();
      expect(a.bottom, closeTo(388.5 + SplashLogoGeometry.dashWidth / 2 * 0, 3));
      expect(b.bottom, lessThan(a.bottom));
    });
  });

  group('robustness (phones, odd screens, failures)', () {
    bool finite(double v) => v.isFinite;

    test('every frame value is finite for every millisecond, including out-of-range times', () {
      final tl = SplashTimeline();
      final f = SplashFrame();
      final buf = SmokeBuffer();
      for (final yb in [640.0, 800.0, 1200.0]) {
        for (var t = -50.0; t <= 1900; t += 1) {
          tl.frame(t, f, yb);
          for (final v in [f.tyreX, f.tyreY, f.tyreScale, f.squashX, f.squashY, f.groundY, f.air, f.thetaDeg,
              f.rotDeg, f.detailAlpha, f.phi, f.roadClipBottom, f.wordAlpha, f.wordOffset]) {
            expect(finite(v), isTrue, reason: 'non-finite value at t=$t');
          }
          expect(f.tyreScale, greaterThan(0));
          final n = tl.smoke(t, buf);
          for (var i = 0; i < n * 4; i++) {
            expect(finite(buf.transforms[i]) && finite(buf.rects[i]), isTrue, reason: 'smoke at t=$t');
          }
        }
      }
    });

    testWidgets('paints without error on unusual screen shapes at every tier', (tester) async {
      final timeline = SplashTimeline();
      final logo = SplashLogoGeometry();
      late SplashSprites sprites;
      late ui.ImageShader shader;
      late ui.Image shaderImage;
      await tester.runAsync(() async {
        sprites = await SplashSprites.load();
        shaderImage = sprites.tread.clone();
        shader = ui.ImageShader(shaderImage, TileMode.clamp, TileMode.repeated, Matrix4.identity().storage);
      });
      final errors = <Object>[];
      const sizes = [
        Size(320, 480), // small old phone
        Size(360, 640),
        Size(411, 891), // tall modern phone
        Size(1080, 2400), // very tall, high resolution
        Size(800, 1280), // tablet portrait
        Size(1280, 800), // tablet landscape
        Size(640, 360), // phone landscape
        Size(100, 100),
        Size(1, 1),
      ];
      for (final tier in SplashTier.values) {
        final clock = ValueNotifier<double>(0);
        final painter = SplashPainter(
            clock: clock, sprites: sprites, treadShader: shader, timeline: timeline,
            quality: SplashQualityMonitor(initial: tier), logo: logo, onError: (e, st) => errors.add(e));
        for (final size in sizes) {
          for (var t = 0.0; t <= 1800; t += 37) {
            clock.value = t;
            final r = ui.PictureRecorder();
            painter.paint(Canvas(r), size);
            r.endRecording().dispose();
          }
        }
        // junk inputs must never throw either
        for (final t in [double.nan, double.infinity, -1.0, 99999.0]) {
          clock.value = t;
          final r = ui.PictureRecorder();
          painter.paint(Canvas(r), const Size(360, 640));
          r.endRecording().dispose();
        }
      }
      expect(errors, isEmpty);
      shader.dispose();
      sprites.dispose();
    });

    testWidgets('a failing draw is reported once, never thrown, and leaves the canvas balanced', (tester) async {
      late SplashSprites sprites;
      late ui.ImageShader shader;
      await tester.runAsync(() async {
        sprites = await SplashSprites.load();
        shader = ui.ImageShader(sprites.tread.clone(), TileMode.clamp, TileMode.repeated, Matrix4.identity().storage);
      });
      final errors = <Object>[];
      final clock = ValueNotifier<double>(1800);
      final painter = SplashPainter(
          clock: clock, sprites: sprites, treadShader: shader, timeline: SplashTimeline(),
          quality: SplashQualityMonitor(initial: SplashTier.full), logo: SplashLogoGeometry(),
          onError: (e, st) => errors.add(e));
      sprites.dispose(); // simulate a lost / invalid GPU image
      final r = ui.PictureRecorder();
      final canvas = Canvas(r);
      final before = canvas.getSaveCount();
      painter.paint(canvas, const Size(360, 640)); // must not throw
      painter.paint(canvas, const Size(360, 640)); // already failed: no second report
      expect(errors, hasLength(1));
      expect(canvas.getSaveCount(), before);
      r.endRecording().dispose();
    });

    testWidgets('a sprite that fails to load makes load() throw cleanly (no half-built object)', (tester) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key.endsWith('smoke.png')) return null; // missing asset
        final bytes = File(key).readAsBytesSync();
        return ByteData.sublistView(bytes);
      });
      addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
      Object? caught;
      await tester.runAsync(() async {
        try {
          await SplashSprites.load();
        } catch (e) {
          caught = e;
        }
      });
      expect(caught, isNotNull);
    });
  });

  // Dart-side cost of recording one frame (UI thread work, excludes GPU raster).
  // Informational: prints average / worst ms per frame for each quality tier.
  testWidgets('frame recording cost per tier (informational)', (tester) async {
    final timeline = SplashTimeline();
    final logo = SplashLogoGeometry();
    late SplashSprites sprites;
    late ui.ImageShader shader;
    await tester.runAsync(() async {
      sprites = await SplashSprites.load();
      shader = ui.ImageShader(sprites.tread, TileMode.clamp, TileMode.repeated,
          Matrix4.identity().storage, filterQuality: FilterQuality.medium);
    });
    for (final tier in SplashTier.values) {
      final clock = ValueNotifier<double>(0);
      final painter = SplashPainter(
          clock: clock, sprites: sprites, treadShader: shader, timeline: timeline,
          quality: SplashQualityMonitor(initial: tier), logo: logo);
      // warm-up
      for (var t = 0.0; t <= 1800; t += 50) {
        clock.value = t;
        final r = ui.PictureRecorder();
        painter.paint(Canvas(r), const Size(360, 640));
        r.endRecording().dispose();
      }
      final sw = Stopwatch();
      var worst = 0.0, total = 0.0, n = 0;
      for (var t = 0.0; t <= 1800; t += 1000 / 60) {
        clock.value = t;
        sw
          ..reset()
          ..start();
        final r = ui.PictureRecorder();
        painter.paint(Canvas(r), const Size(360, 640));
        r.endRecording().dispose();
        sw.stop();
        final ms = sw.elapsedMicroseconds / 1000;
        total += ms;
        n++;
        if (ms > worst) worst = ms;
      }
      // ignore: avoid_print
      print('splash ${tier.name.padRight(6)} avg ${(total / n).toStringAsFixed(2)} ms  worst ${worst.toStringAsFixed(2)} ms  ($n frames)');
      expect(total / n, lessThan(16), reason: 'recording a frame must fit comfortably in a 60fps budget');
    }
    sprites.dispose();
  });

  testWidgets('renders unusual screen shapes (set SPLASH_OUT to save PNGs)', (tester) async {
    final out = Platform.environment['SPLASH_OUT'];
    if (out == null) return;
    final clock = ValueNotifier<double>(0);
    late SplashSprites sprites;
    late ui.ImageShader shader;
    await tester.runAsync(() async {
      sprites = await SplashSprites.load();
      shader = ui.ImageShader(sprites.tread.clone(), TileMode.clamp, TileMode.repeated, Matrix4.identity().storage);
    });
    for (final size in const [Size(411, 891), Size(1280, 800), Size(320, 480)]) {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.white,
            child: CustomPaint(
              size: Size.infinite,
              painter: SplashPainter(
                  clock: clock, sprites: sprites, treadShader: shader, timeline: SplashTimeline(),
                  quality: SplashQualityMonitor(initial: SplashTier.full), logo: SplashLogoGeometry()),
            ),
          ),
        ),
      ));
      for (final t in [250.0, 600, 1800]) {
        clock.value = t.toDouble();
        await tester.pump();
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.0);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$out/s_${size.width.toInt()}x${size.height.toInt()}_${t.toInt()}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  // Renders frames to PNG so they can be compared with the prototype. Run with
  //   SPLASH_OUT=<dir> flutter test test/splash_animation_test.dart
  testWidgets('renders key frames (set SPLASH_OUT to save PNGs)', (tester) async {
    final out = Platform.environment['SPLASH_OUT'];
    final clock = ValueNotifier<double>(0);
    final timeline = SplashTimeline();
    final logo = SplashLogoGeometry();
    final quality = SplashQualityMonitor(initial: SplashTier.full);
    late SplashSprites sprites;
    late ui.ImageShader shader;
    await tester.runAsync(() async {
      sprites = await SplashSprites.load();
      shader = ui.ImageShader(sprites.tread, TileMode.clamp, TileMode.repeated,
          Matrix4.identity().storage, filterQuality: FilterQuality.medium);
    });
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: Colors.white,
          child: CustomPaint(
            size: Size.infinite,
            painter: SplashPainter(
                clock: clock, sprites: sprites, treadShader: shader, timeline: timeline, quality: quality, logo: logo),
          ),
        ),
      ),
    ));
    for (final t in [0.0, 100, 250, 333, 400, 500, 600, 340, 380, 420, 460, 500, 540, 570, 590, 620, 660, 700, 800, 940, 975, 1000, 1008, 900, 1000, 1100, 1300, 1500, 1600, 1800]) {
      clock.value = t.toDouble();
      await tester.pump();
      if (out != null) {
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 3.0);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final fr = SplashFrame();
          timeline.frame(t.toDouble(), fr, 640);
          File('$out/meta.csv')
              .writeAsStringSync('${t.toInt()},${fr.tyreX},${fr.tyreY},${fr.tyreScale}\n', mode: FileMode.append);
          File('$out/f_${t.toInt()}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }
    expect(tester.takeException(), isNull);
    sprites.dispose();
    await tester.binding.setSurfaceSize(null);
  });
}
