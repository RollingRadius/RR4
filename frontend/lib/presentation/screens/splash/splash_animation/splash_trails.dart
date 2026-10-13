import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'splash_timeline.dart';

/// The speed trails that stream back from the tyre's two sides while it starts to run:
/// near-black streaks on the left, blue streaks on the right.
///
/// **Driven by the tyre's real motion, not by a clock.** Every streak is pinned to the road at the
/// spot where the tyre was when it appeared, and stretches behind the tyre by exactly the distance the
/// tyre has actually travelled since. When the tyre is slow the streaks barely grow; at its peak
/// speed they stretch fastest; if it stood still they would not move at all.
///
/// Anime / motion-graphics speed-line craft:
/// - tapered ribbons that thin out with distance (depth), with a slight curve and varied length / thickness;
/// - two kinds: thick "main" streaks (halo + core + highlight) and long thin hairlines;
/// - after growing to full length a streak's tail trims away ("trim path") while it fades;
/// - the blue side has a deep-blue edge, a saturated core and a near-white highlight so it stays readable
///   over both the white background and the blue road shoulders.
/// Every streak of a frame is batched into one `drawVertices` call with per-vertex colours
/// (no saveLayer, no blur).
class SplashTrails {
  SplashTrails(this.timeline) {
    var n = 0;
    for (var i = 0; i < mainCount; i++, n++) {
      final side = i.isEven ? -1.0 : 1.0;
      streaks.add(TrailStreak(
        left: side < 0,
        hairline: false,
        lateral: side * (40 + 60 * splashRnd(n, 1, 3)),
        height: 200 * splashRnd(n, 2, 3),
        length: .45 + .7 * splashRnd(n, 3, 3),
        spawnDist: minSpawn + (maxSpawn - minSpawn) * splashRnd(n, 4, 3),
        span: minSpan + (maxSpan - minSpan) * splashRnd(n, 5, 3),
        thickness: .55 + .5 * splashRnd(n, 6, 3),
        bend: side * (3 + 9 * splashRnd(n, 7, 3)),
      ));
    }
    for (var i = 0; i < hairCount; i++, n++) {
      final side = i.isEven ? -1.0 : 1.0;
      streaks.add(TrailStreak(
        left: side < 0,
        hairline: true,
        lateral: side * (38 + 78 * splashRnd(n, 1, 3)),
        height: 210 * splashRnd(n, 2, 3),
        length: .8 + .9 * splashRnd(n, 3, 3),
        spawnDist: minSpawn + (maxSpawn - minSpawn) * splashRnd(n, 4, 3),
        span: minSpan + (maxSpan - minSpan) * splashRnd(n, 5, 3),
        thickness: .22 + .16 * splashRnd(n, 6, 3),
        bend: side * (4 + 12 * splashRnd(n, 7, 3)),
      ));
    }
  }

  final SplashTimeline timeline;

  static const int mainCount = 26, hairCount = 24;
  static const int count = mainCount + hairCount;
  static const int _segments = 7;
  static const int _layers = 3;
  static const int _vertsPerStrip = (_segments + 1) * 2;

  /// A streak appears once the tyre has travelled [minSpawn]..[maxSpawn] px, and lives for [minSpan]..[maxSpan]
  /// further px of travel. Spawn + span stays below the end of the straight road (about 256 px).
  static const double minSpawn = 4, maxSpawn = 100, minSpan = 90, maxSpan = 150;

  /// The streaks stretch in proportion to how far the tyre has moved, amplified by this factor so the
  /// effect reads clearly (it is still exactly proportional: no tyre motion, no stretching).
  static const double stretchGain = 2.4;

  final List<TrailStreak> streaks = [];

  final Float32List _pos = Float32List(count * _layers * _vertsPerStrip * 2);
  final Int32List _col = Int32List(count * _layers * _vertsPerStrip);
  final Uint16List _idx = Uint16List(count * _layers * _segments * 6);

  // [outer glow/edge, core, highlight]
  static const List<int> _leftRgb = [0x4A5563, 0x0F1319, 0xB4BFCB];
  static const List<int> _rightRgb = [0x0F3B57, 0x2478B0, 0xA2D3F0];
  static const List<double> _layerAlpha = [.22, .68, .80];
  static const List<double> _layerWidth = [2.2, 1.0, .30];

  static double _easeIn(double x) => x * x;
  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  /// How far (in perspective depth units) the streak has stretched behind the tyre when the tyre has
  /// travelled [distNow] px: exactly how much the tyre has receded since the streak was pinned to the road.
  /// Zero before the streak appears; capped at the streak's full length.
  double reach(TrailStreak st, double distNow) {
    if (distNow <= st.spawnDist) return 0;
    final grown = 1 / timeline.scaleAtDistance(distNow) - 1 / timeline.scaleAtDistance(st.spawnDist);
    return math.min(grown * stretchGain, st.fullLength);
  }

  /// Builds this frame's trails. Returns null when nothing is visible.
  ui.Vertices? build(double t) {
    if (t < SplashTiming.burnEnd) return null;
    final distNow = timeline.dist(t);
    if (distNow <= 0) return null;
    final depthNow = 1 / timeline.scaleAtDistance(distNow);
    final tyreScale = 1 / depthNow;
    const kk = 1 / SplashLayout.perspectiveK;
    var vc = 0, ic = 0;
    final px = List<double>.filled(_segments + 1, 0), py = List<double>.filled(_segments + 1, 0);
    final qs = List<double>.filled(_segments + 1, 0);
    for (final st in streaks) {
      if (distNow <= st.spawnDist || distNow >= st.spawnDist + st.span) continue;
      final u = (distNow - st.spawnDist) / st.span;
      final env = math.pow(math.sin(math.pi * u), .6).toDouble();
      // visible slice (distance behind the tyre): it stretches out at the tyre's speed, then its tail trims away
      final far = reach(st, distNow);
      final near = st.fullLength * .98 * _easeIn(_clamp01((u - .35) / .65));
      if (far - near < .05) continue;
      for (var k = 0; k <= _segments; k++) {
        final o = near + (far - near) * (k / _segments);
        qs[k] = o / st.fullLength;
        final s = 1 / math.max(.2, depthNow - o);
        px[k] = SplashLayout.roadX + st.lateral * s + st.bend * qs[k] * qs[k];
        py[k] = SplashLayout.horizon + (kk - st.height) * s;
      }
      final headHalf = (0.8 + 1.1 * tyreScale) * st.thickness;
      final rgb = st.left ? _leftRgb : _rightRgb;
      for (var layer = st.hairline ? 1 : 0; layer < _layers; layer++) {
        final base = vc;
        final lw = _layerWidth[layer] * (st.hairline && layer == 1 ? .8 : 1);
        final la = _layerAlpha[layer] * (st.hairline ? .75 : 1) * (st.left ? 1 : 1.3);
        for (var k = 0; k <= _segments; k++) {
          final a = k < _segments ? k : k - 1;
          var tx = px[a + 1] - px[a], ty = py[a + 1] - py[a];
          final len = math.sqrt(tx * tx + ty * ty);
          if (len < 1e-6) {
            tx = 0;
            ty = 1;
          } else {
            tx /= len;
            ty /= len;
          }
          final q = _clamp01(qs[k]);
          final g = k / _segments;
          final half = (headHalf * math.pow(1 - q, .65) + .15) * lw;
          final nx = -ty * half, ny = tx * half;
          // fades with distance, and softly at the inner (tyre-side) end of the stretching slice
          final soft = _clamp01(g / .3);
          final alpha = (la * env * math.pow(1 - q, .85) * (.25 + .75 * soft)).clamp(0.0, 1.0);
          final color = ((alpha * 255).round() << 24) | rgb[layer];
          _pos[vc * 2] = px[k] + nx;
          _pos[vc * 2 + 1] = py[k] + ny;
          _col[vc++] = color;
          _pos[vc * 2] = px[k] - nx;
          _pos[vc * 2 + 1] = py[k] - ny;
          _col[vc++] = color;
        }
        for (var k = 0; k < _segments; k++) {
          final a = base + k * 2;
          _idx[ic++] = a;
          _idx[ic++] = a + 1;
          _idx[ic++] = a + 2;
          _idx[ic++] = a + 1;
          _idx[ic++] = a + 3;
          _idx[ic++] = a + 2;
        }
      }
    }
    if (vc == 0) return null;
    return ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(_pos, 0, vc * 2),
      colors: Int32List.sublistView(_col, 0, vc),
      indices: Uint16List.sublistView(_idx, 0, ic),
    );
  }
}

class TrailStreak {
  TrailStreak({
    required this.left,
    required this.hairline,
    required this.lateral,
    required this.height,
    required this.length,
    required this.spawnDist,
    required this.span,
    required this.thickness,
    required this.bend,
  });

  final bool left; // left side = near-black, right side = blue
  final bool hairline; // long thin companion line instead of a main streak
  final double lateral, height, length, spawnDist, span, thickness, bend;

  /// Full length in perspective depth units.
  double get fullLength => length * 1.6;
}
