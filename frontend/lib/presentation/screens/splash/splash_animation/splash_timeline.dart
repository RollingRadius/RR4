import 'dart:math' as math;
import 'dart:typed_data';

/// Pure-Dart motion model for the animated splash (Option C: the tyre runs up a
/// logo-style road, then the road and tyre become the logo).
///
/// Everything is expressed in a 360x640 "design" space and driven by wall-clock
/// milliseconds, so a slow device drops frames but the splash still ends on time.

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
double lerpD(double a, double b, double t) => a + (b - a) * t;
double easeOut(double t) => 1 - (1 - t) * (1 - t);
double easeInOut(double t) =>
    t < .5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2).toDouble() / 2;

/// Deterministic pseudo-random in 0..1 (same function the sprites were baked with).
double splashRnd(int i, int j, int k) {
  final v = math.sin(i * 127.1 + j * 311.7 + k * 74.7) * 43758.5453;
  return v - v.floorToDouble();
}

class SplashTiming {
  static const double totalMs = 1800; // whole splash; the last stretch just holds the finished logo
  static const double smokeStart = 50;
  static const double smokeEnd = 830;
  static const double burnEnd = 333; // tyre spins in place until here, then runs
  static const double rollEnd = 700; // tyre reaches the end of the road
  static const double jumpEnd = 950; // tyre lands in the P notch
  static const double swap = 1010; // tyre becomes the logo wheel
  static const double roadShrink = 780; // perspective road starts merging into the logo road
  static const double roadEnd = 1039; // ...and has fully merged
  static const double wordStart = 1042; // wordmark starts appearing
  static const double wordEnd = 1600; // ...and is fully in; then 200ms of hold on the finished logo
}

class SplashLayout {
  static const double designW = 360, designH = 640;
  static const double roadX = 138.5; // centre line of the road
  static const double ground = 377; // bottom of the logo mark
  static const double finalWheelX = 234.9, finalWheelY = 265.8, finalScale = 0.2697;
  static const double treadHalfWidth = 36; // tyre art units
  static const double horizon = 261, perspectiveK = 0.0031;
  static const double startY = 540; // ground contact of the tyre at t=0
  static const double roadStraightEndY = 283.9; // logo road: straight part ends here, then it arcs
  static const double arcCx = 214.9, arcCy = 283.9, arcR = 76.3;
  static const double arcSweep = 53 * math.pi / 180;
  // logo transform (logo art lives in a 512 space)
  static const double logoTx = 27.7, logoTy = 151.7, logoScale = 0.58;
  // wordmark
  static const double wordCx = 180, wordBaseline = 417, wordWidth = 188;
}

/// Where the tyre is at an instant.
class TyrePose {
  double x = 0, g = 0, s = 0, turn = 0, d = 0; // g = ground contact y, s = scale, turn = rad
}

/// Everything the painter needs for one frame.
class SplashFrame {
  double t = 0;
  // tyre
  double tyreX = 0, tyreY = 0, tyreScale = 0, squashX = 1, squashY = 1;
  double groundY = 0, air = 0, thetaDeg = 0, rotDeg = 0;
  double tyreAlpha = 1, detailAlpha = 1;
  bool tyreVisible = true, wheelVisible = false;
  // road
  double phi = 0; // dash scroll (in dash pitches)
  double roadClipBottom = 0;
  bool roadVisible = true;
  // text
  double wordAlpha = 0, wordOffset = 0;
}

class SplashTimeline {
  SplashTimeline() {
    _buildRotationTable();
  }

  static const double _omegaCap = 8.2; // rad/s: keeps the tread from strobing at 60fps
  // Viewing angle of the tyre, in degrees from face-on: exactly 90 (pure rear view, tread only) while it
  // runs straight, then it eases to 31 as the road curves, which is when the side and rim come into view.
  static const double _thStart = 90, _thTurnEnd = 31;
  static const double dashPhi = 8; // dash scroll at t=0, in dash pitches

  final double _l1 = SplashLayout.startY - SplashLayout.roadStraightEndY;
  late final double totalDist = _l1 + SplashLayout.arcR * SplashLayout.arcSweep;
  final double _db = SplashLayout.startY - SplashLayout.ground;
  final double _sBase = SplashLayout.perspectiveK * (SplashLayout.ground - SplashLayout.horizon);
  static final int _rotSteps = SplashTiming.totalMs.toInt() + 1;
  final Float32List _rot = Float32List(_rotSteps + 1);
  late final TyrePose end;
  late final double _jumpFromY;
  late final double _thetaEnd;

  void _buildRotationTable() {
    end = pose(SplashTiming.rollEnd, TyrePose());
    _jumpFromY = end.g - 100 * end.s;
    _thetaEnd = _thetaForTurn(end.turn);
    var r = 0.0;
    for (var ms = 1; ms <= _rotSteps; ms++) {
      final v = (dist(ms.toDouble()) - dist(ms - 1.0)) / .001;
      final rad = 100 * _scaleAt(math.min(totalDist, dist(ms.toDouble())));
      final om = (ms < SplashTiming.burnEnd || ms >= SplashTiming.rollEnd)
          ? _omegaCap
          : math.min(_omegaCap, v / rad);
      r += om * .001;
      _rot[ms] = r;
    }
  }

  /// Distance (px) along the road at which the straight part ends and the curve begins.
  double get straightDistance => _l1;

  /// Perspective scale of the tyre once it has travelled [d] px along the road.
  double scaleAtDistance(double d) => _scaleAt(d < 0 ? 0 : (d > totalDist ? totalDist : d));

  double dist(double t) => totalDist *
      easeInOut(clamp01((t - SplashTiming.burnEnd) / (SplashTiming.rollEnd - SplashTiming.burnEnd)));

  double _scaleAt(double d) => d <= _db
      ? SplashLayout.perspectiveK * ((SplashLayout.startY - d) - SplashLayout.horizon)
      : lerpD(_sBase, SplashLayout.finalScale, (d - _db) / (totalDist - _db));

  /// Tyre pose while it runs along the road (before the hop). Writes into [out].
  TyrePose pose(double t, TyrePose out) {
    final d = dist(t);
    if (d <= _l1) {
      out
        ..x = SplashLayout.roadX
        ..g = SplashLayout.startY - d
        ..turn = 0;
    } else {
      final a = (d - _l1) / SplashLayout.arcR;
      out
        ..x = SplashLayout.arcCx + SplashLayout.arcR * math.cos(math.pi + a)
        ..g = SplashLayout.arcCy + SplashLayout.arcR * math.sin(math.pi + a)
        ..turn = a;
    }
    out
      ..s = _scaleAt(d)
      ..d = d;
    return out;
  }

  double _thetaForTurn(double turn) =>
      lerpD(_thStart, _thTurnEnd, clamp01(turn / SplashLayout.arcSweep));

  double thetaAt(double t, TyrePose scratch) {
    if (t < SplashTiming.rollEnd) {
      return _thetaForTurn(pose(t, scratch).turn);
    }
    final p = (t - SplashTiming.rollEnd) / (SplashTiming.jumpEnd - SplashTiming.rollEnd);
    return lerpD(_thetaEnd, 0, easeInOut(clamp01((p - .08) / .82)));
  }

  double rotAt(double t) => _rot[math.min(_rotSteps, math.max(0, t.floor()))];

  final TyrePose _scratch = TyrePose();

  void frame(double t, SplashFrame f, double yBottom) {
    t = t < 0 ? 0 : (t > SplashTiming.totalMs ? SplashTiming.totalMs : t);
    f.t = t;
    const s0 = SplashLayout.finalScale;
    double x, y, s, sx = 1, sy = 1, gy, air = 0;
    if (t < SplashTiming.rollEnd) {
      final p = pose(t, _scratch);
      x = p.x;
      s = p.s;
      gy = p.g;
      final c = clamp01((t - 640) / 60);
      sy = 1 - .1 * c;
      sx = 1 + .08 * c;
      y = gy - 100 * s * sy;
    } else if (t < SplashTiming.jumpEnd) {
      final p = (t - SplashTiming.rollEnd) / (SplashTiming.jumpEnd - SplashTiming.rollEnd);
      x = lerpD(end.x, SplashLayout.finalWheelX, p);
      s = lerpD(end.s, s0, easeOut(p));
      y = lerpD(_jumpFromY, SplashLayout.finalWheelY, p) - 4 * 58 * p * (1 - p);
      gy = lerpD(end.g, SplashLayout.ground, p);
      air = 4 * p * (1 - p);
      final st = p < .5 ? math.sin(math.pi * p / .5) * .13 : 0.0;
      sy = 1 + st;
      sx = 1 / sy;
    } else {
      x = SplashLayout.finalWheelX;
      s = s0;
      y = SplashLayout.finalWheelY;
      gy = SplashLayout.ground;
      if (t < SplashTiming.swap) {
        final k = math.sin(math.pi * (t - SplashTiming.jumpEnd) / (SplashTiming.swap - SplashTiming.jumpEnd)) * .14;
        sy = 1 - k;
        sx = 1 + k;
        // squash around the centre (it widens as it flattens), so the wheel keeps covering the arch's tip
        y = SplashLayout.finalWheelY;
      }
    }
    f
      ..tyreX = x
      ..tyreY = y
      ..tyreScale = s
      ..squashX = sx
      ..squashY = sy
      ..groundY = gy
      ..air = air
      ..thetaDeg = thetaAt(t, _scratch)
      ..rotDeg = rotAt(t) * 180 / math.pi
      ..detailAlpha = 1 - clamp01((t - 870) / 110)
      ..tyreVisible = t < SplashTiming.swap
      ..wheelVisible = t >= SplashTiming.swap;
    final e = easeInOut(clamp01(t / SplashTiming.roadEnd));
    f
      ..phi = dashPhi * (1 - e)
      ..roadVisible = t < SplashTiming.roadEnd
      ..roadClipBottom = yBottom -
          (yBottom - (SplashLayout.ground - 1.5)) *
              easeInOut(clamp01((t - SplashTiming.roadShrink) / (SplashTiming.roadEnd - SplashTiming.roadShrink)))
      ..wordAlpha = easeOut(clamp01((t - SplashTiming.wordStart) / (SplashTiming.wordEnd - SplashTiming.wordStart)))
      ..wordOffset = 12 * (1 - easeOut(clamp01((t - SplashTiming.wordStart) / (SplashTiming.wordEnd - SplashTiming.wordStart))));
  }

  // ---------------------------------------------------------------- smoke
  /// Smoke emission schedule: (spawn time, lateral position across the tyre's base).
  static final List<List<double>> puffSchedule = _buildSchedule();

  static List<List<double>> _buildSchedule() {
    final list = <List<double>>[];
    for (var k = 0; k <= 10; k++) {
      final fs = k <= 3 ? [-.8, 0.0, .8] : [-.5, .5];
      for (final f in fs) {
        list.add([SplashTiming.smokeStart + k * 48.0, f]);
      }
    }
    list.add([SplashTiming.rollEnd + 10, -.5]);
    list.add([SplashTiming.rollEnd + 30, .5]);
    return list;
  }

  /// Fills [buf] with the live puffs at time [t]. [stride] > 1 thins the smoke on slower tiers.
  int smoke(double t, SmokeBuffer buf, {int stride = 1}) {
    var n = 0;
    if (t < SplashTiming.smokeStart) return 0;
    final tmp = TyrePose();
    for (var i = 0; i < puffSchedule.length; i += stride) {
      final ts = puffSchedule[i][0], f = puffSchedule[i][1];
      final life = math.min(880.0, SplashTiming.smokeEnd - ts);
      final age = t - ts;
      if (life <= 0 || age < 0 || age >= life) continue;
      final k = age / life;
      final pp = ts < SplashTiming.rollEnd ? pose(ts, tmp) : end;
      final hot = ts < SplashTiming.burnEnd;
      final th0 = thetaAt(math.min(ts, SplashTiming.rollEnd), _scratch) * math.pi / 180;
      final halfW = (SplashLayout.treadHalfWidth * math.sin(th0) + 100 * math.cos(th0)) * pp.s;
      final bx = pp.x + f * halfW * .9 + f * k * 14 * pp.s * 2;
      final by = pp.g - 6 - k * 78 * pp.s * 1.4 - (i % 3) * 3 * pp.s * 2;
      final rb = (20 + (i % 4) * 5) * pp.s * 1.2 * (hot ? 1.15 : 1);
      final grow = lerpD(hot ? .85 : .5, 1, easeOut(math.min(1, k * 2)));
      final alpha = math.max(0, 1 - math.pow(k, 1.5).toDouble()) * (hot ? .55 : .5);
      if (alpha <= .01) continue;
      final sc = rb * grow / SmokeBuffer.refRadius;
      final step = ((k / .92) * (SmokeBuffer.steps - 1)).round().clamp(0, SmokeBuffer.steps - 1).toInt();
      buf.add(n++, bx, by, sc, alpha, i % SmokeBuffer.variants, step);
    }
    return n;
  }
}

/// Reusable typed buffers for one `drawRawAtlas` call (no per-frame allocation).
class SmokeBuffer {
  static const int cell = 256, steps = 7, variants = 4;
  static const double refRadius = 64;
  static const int capacity = 40;

  final Float32List transforms = Float32List(capacity * 4);
  final Float32List rects = Float32List(capacity * 4);
  final Int32List colors = Int32List(capacity);

  void add(int n, double cx, double cy, double scale, double alpha, int variant, int step) {
    final o = n * 4;
    const half = cell / 2;
    transforms[o] = scale; // scos
    transforms[o + 1] = 0; // ssin
    transforms[o + 2] = cx - half * scale; // tx
    transforms[o + 3] = cy - half * scale; // ty
    rects[o] = step * cell.toDouble();
    rects[o + 1] = variant * cell.toDouble();
    rects[o + 2] = (step + 1) * cell.toDouble();
    rects[o + 3] = (variant + 1) * cell.toDouble();
    colors[n] = ((alpha.clamp(0.0, 1.0) * 255).round() << 24) | 0x00FFFFFF;
  }
}
