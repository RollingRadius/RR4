import 'dart:math' as math;
import 'dart:ui';

/// The final RollingRadius mark as clean vector paths, in the logo's own 512 space.
/// Measured from the original logo (see docs/splash_options/option_B/source/clean_logo.py).
class SplashLogoGeometry {
  SplashLogoGeometry() {
    outer = _buildOuter();
    road = _buildRoad();
    edgeLeft = _buildEdge(const Offset(308.5, 227), 139.5 - 4.6);
    edgeRight = _buildEdge(const Offset(336.5, 229), 123.5 + 4.6);
    dashLine = Path()
      ..moveTo(_dashX, _bottom)
      ..lineTo(_dashX, 228)
      ..arcToPoint(
        const Offset(243.58, 123),
        radius: const Radius.circular(131.5),
        clockwise: true,
      );
    final metrics = dashLine.computeMetrics().toList();
    dashMetric = metrics.first;
    dashLength = dashMetric.length;
  }

  static const double _bottom = 388.5;
  static const double _dashX = 191;
  static const double dashLen = 10, dashGap = 15, dashWidth = 4.6;
  static const double pitch = dashLen + dashGap;
  // Sits a few units up-right of the measured centre so the wheel tucks against the arch's sharp tip
  // (as in the original logo) instead of leaving a hairline of white between them.
  static const Offset wheelCenter = Offset(357.2, 196.7);
  static const double wheelRadius = 46.5;

  late final Offset tip; // the arch's sharp tip next to the wheel
  late final Path outer; // the blue arch silhouette (also the clip for the road)
  late final Path road;
  late final Path edgeLeft, edgeRight;
  late final Path dashLine;
  late final PathMetric dashMetric;
  late final double dashLength;

  Path? _finalDashes;

  Path _buildOuter() {
    // tip where the sweep circle meets the inner dome circle
    const oc = Offset(301.5, 225), dc = Offset(337, 213.9);
    const orad = 108.2, drad = 71.7;
    final d = (dc - oc).distance;
    final a = (orad * orad - drad * drad + d * d) / (2 * d);
    final h = math.sqrt(orad * orad - a * a);
    final m = oc + (dc - oc) * (a / d);
    final dir = (dc - oc) / d;
    final p1 = Offset(m.dx + h * dir.dy, m.dy - h * dir.dx);
    final p2 = Offset(m.dx - h * dir.dy, m.dy + h * dir.dx);
    tip = p1.dy < p2.dy ? p1 : p2;
    return Path()
      ..moveTo(126.5, _bottom)
      ..lineTo(126.5, 214.5)
      ..arcToPoint(const Offset(224, 117), radius: const Radius.circular(97.5), clockwise: true)
      ..lineTo(301.5, 117)
      ..arcToPoint(tip, radius: const Radius.circular(orad), clockwise: true)
      ..arcToPoint(const Offset(265.3, 213.9), radius: const Radius.circular(drad), clockwise: false)
      ..lineTo(265.3, _bottom)
      ..close();
  }

  Path _buildRoad() {
    return Path()
      ..moveTo(169, _bottom)
      ..lineTo(169, 227)
      ..arcToPoint(const Offset(239.08, 106), radius: const Radius.circular(139.5), clockwise: true)
      ..lineTo(325.40, 106)
      ..arcToPoint(const Offset(213, 229), radius: const Radius.circular(123.5), clockwise: false)
      ..lineTo(213, _bottom)
      ..close();
  }

  Path _buildEdge(Offset c, double r) {
    const yTop = 106.0;
    final x = c.dx - math.sqrt(r * r - (yTop - c.dy) * (yTop - c.dy));
    return Path()
      ..moveTo(c.dx - r, _bottom)
      ..lineTo(c.dx - r, c.dy)
      ..arcToPoint(Offset(x, yTop), radius: Radius.circular(r), clockwise: true);
  }

  /// Dash segments of the centre line. [phi] shifts the pattern up the road (in dash pitches).
  /// At phi == 0 this is the final logo's dash pattern.
  Path dashes(double phi) {
    if (phi <= 0.0001) return _finalDashes ??= _compute(0);
    return _compute(phi);
  }

  Path _compute(double phi) {
    final p = Path();
    final shift = pitch * phi;
    final kMin = ((-shift - dashLen) / pitch).floor();
    final kMax = ((dashLength - shift) / pitch).ceil();
    for (var k = kMin; k <= kMax; k++) {
      final s0 = k * pitch + shift;
      final a = math.max(0.0, s0);
      final b = math.min(dashLength, s0 + dashLen);
      if (b > a) p.addPath(dashMetric.extractPath(a, b), Offset.zero);
    }
    return p;
  }
}
