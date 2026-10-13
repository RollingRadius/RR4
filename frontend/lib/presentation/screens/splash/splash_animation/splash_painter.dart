import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/rendering.dart';

import 'splash_logo_geometry.dart';
import 'splash_quality.dart';
import 'splash_sprites.dart';
import 'splash_timeline.dart';
import 'splash_trails.dart';

/// Draws one frame of the splash from the timeline and the pre-baked sprites.
/// No saveLayer, no blur, no per-frame image decoding: sprites are only transformed
/// (rim = a few drawImageRect, tread = one textured mesh, smoke = one drawRawAtlas).
class SplashPainter extends CustomPainter {
  SplashPainter({
    required this.clock,
    required this.sprites,
    required this.treadShader,
    required this.timeline,
    required this.quality,
    required this.logo,
    this.onError,
  }) : super(repaint: clock);

  /// Called once (never while painting) if drawing throws, so the caller can fall back to a plain logo.
  final void Function(Object error, StackTrace stack)? onError;
  bool _failed = false;

  final ValueListenable<double> clock; // elapsed milliseconds
  final SplashSprites sprites;
  final ui.ImageShader treadShader;
  final SplashTimeline timeline;
  final SplashQualityMonitor quality;
  final SplashLogoGeometry logo;

  // ---- reusable objects (nothing is allocated per frame except tiny paths) ----
  final SplashFrame _f = SplashFrame();
  final SmokeBuffer _smoke = SmokeBuffer();
  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;
  final Paint _image = Paint()..filterQuality = FilterQuality.medium;
  final Paint _atlas = Paint()..filterQuality = FilterQuality.low;
  final Paint _meshPaint = Paint();
  final Map<int, _TreadMesh> _meshes = {};

  static const Color _blue = Color(0xFF3997CD);
  late final SplashTrails _trails = SplashTrails(timeline);

  // perspective road constants (design px)
  static const double _roadHalf0 = 12.76, _roadFlare = .11, _pz = .125, _lz = .05;
  static const double _shoulderL = 1.93, _shoulderR = 2.38;

  static double _hw(double y) => _roadHalf0 + (y - SplashLayout.ground) * _roadFlare;
  static double _yz(double z) =>
      SplashLayout.horizon + (SplashLayout.ground - SplashLayout.horizon) / z;

  @override
  void paint(Canvas canvas, Size size) {
    if (_failed || size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    final saveCount = canvas.getSaveCount();
    try {
      _paintFrame(canvas, size);
    } catch (e, st) {
      // Never let an unexpected GPU/driver/platform difference break app start-up.
      _failed = true;
      onError?.call(e, st);
    } finally {
      canvas.restoreToCount(saveCount);
    }
  }

  void _paintFrame(Canvas canvas, Size size) {
    final raw = clock.value;
    final t = raw.isFinite ? raw.clamp(0.0, SplashTiming.totalMs).toDouble() : 0.0;
    final k = math.min(size.width / SplashLayout.designW, size.height / SplashLayout.designH);
    final designH = size.height / k;
    final yBottom = (SplashLayout.designH + designH) / 2;
    final tier = quality.tier;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(k);
    canvas.translate(-SplashLayout.designW / 2, -SplashLayout.designH / 2);

    timeline.frame(t, _f, yBottom);

    if (tier.trails) _drawTrails(canvas, t);
    if (_f.roadVisible) _drawRoad(canvas, tier, yBottom);
    if (tier.shadow) _drawShadow(canvas);
    _drawLogo(canvas);
    if (_f.tyreVisible) _drawTyre(canvas, tier);
    _drawSmoke(canvas, t, tier);
    _drawWordmark(canvas);

    canvas.restore();
  }

  // ------------------------------------------------------------------ trails
  void _drawTrails(Canvas canvas, double t) {
    final verts = _trails.build(t);
    if (verts == null) return;
    canvas.drawVertices(verts, BlendMode.srcOver, _meshPaint..shader = null);
    verts.dispose();
  }

  // -------------------------------------------------------------- perspective road
  Path _quad(double Function(double) left, double Function(double) right, double yTop, double yBottom) {
    return Path()
      ..moveTo(left(yBottom), yBottom)
      ..lineTo(right(yBottom), yBottom)
      ..lineTo(right(yTop), yTop)
      ..lineTo(left(yTop), yTop)
      ..close();
  }

  void _drawRoad(Canvas canvas, SplashTier tier, double yBottom) {
    const x = SplashLayout.roadX;
    const yTop = SplashLayout.ground - 1.5;
    if (_f.roadClipBottom <= yTop) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-2000, yTop, 2000, _f.roadClipBottom));

    // blue shoulders (same proportions as the logo's blue arch)
    _fill.color = _blue;
    canvas.drawPath(_quad((y) => x - _hw(y) * (1 + _shoulderL), (y) => x - _hw(y), yTop, yBottom), _fill);
    canvas.drawPath(_quad((y) => x + _hw(y), (y) => x + _hw(y) * (1 + _shoulderR), yTop, yBottom), _fill);
    // asphalt + worn tyre tracks
    _fill.color = const Color(0xFF000000);
    canvas.drawPath(_quad((y) => x - _hw(y), (y) => x + _hw(y), yTop, yBottom), _fill);
    _fill.color = const Color(0xFF17171A);
    canvas.drawPath(_quad((y) => x - _hw(y) * .55, (y) => x - _hw(y) * .29, yTop, yBottom), _fill);
    canvas.drawPath(_quad((y) => x + _hw(y) * .29, (y) => x + _hw(y) * .55, yTop, yBottom), _fill);

    final zMin = (SplashLayout.ground - SplashLayout.horizon) / (yBottom - SplashLayout.horizon);
    final phi = _f.phi;

    // white edge lines
    _fill.color = const Color(0xE6FFFFFF);
    canvas.drawPath(_quad((y) => x - _hw(y) * .8355, (y) => x - _hw(y) * .7445, yTop, yBottom), _fill);
    canvas.drawPath(_quad((y) => x + _hw(y) * .7445, (y) => x + _hw(y) * .8355, yTop, yBottom), _fill);

    // centre dashes (perspective)
    final n0 = (zMin / _pz - phi).floor() - 1, n1 = (1 / _pz - phi).ceil() + 1;
    final dash = Path();
    for (var n = n0; n <= n1; n++) {
      final z0 = (n + phi) * _pz, z1 = z0 + _lz;
      final a = math.max(z0, zMin), b = math.min(z1, 1.0);
      if (b > a) {
        final yn = _yz(a), yf = _yz(b), hn = .104 * _hw(yn), hf = .104 * _hw(yf);
        dash
          ..moveTo(x - hn, yn)
          ..lineTo(x + hn, yn)
          ..lineTo(x + hf, yf)
          ..lineTo(x - hf, yf)
          ..close();
      }
    }
    _fill.color = const Color(0xFFFFFFFF);
    canvas.drawPath(dash, _fill);
    canvas.restore();
  }

  // -------------------------------------------------------------------- shadow
  void _drawShadow(Canvas canvas) {
    final t = _f.t;
    final th = _f.thetaDeg * math.pi / 180;
    final sn = math.sin(th), cs = math.max(.001, math.cos(th));
    final a = t < SplashTiming.jumpEnd
        ? .22 * (1 - _f.air * .6)
        : .22 * (1 - clamp01((t - SplashTiming.jumpEnd) / 150));
    if (a <= .005) return;
    final rx = (SplashLayout.treadHalfWidth * sn + 100 * cs * .9 + 8) * _f.tyreScale * (1 - _f.air * .5);
    final ry = 100 * _f.tyreScale * .16;
    _fill.color = Color.fromRGBO(0, 0, 0, a);
    canvas.drawOval(Rect.fromCenter(center: Offset(_f.tyreX, _f.groundY), width: rx * 2, height: ry * 2), _fill);
  }

  // ---------------------------------------------------------------------- logo
  void _drawLogo(Canvas canvas) {
    canvas.save();
    canvas.translate(SplashLayout.logoTx, SplashLayout.logoTy);
    canvas.scale(SplashLayout.logoScale);
    _fill.color = _blue;
    canvas.drawPath(logo.outer, _fill);

    canvas.save();
    canvas.clipPath(logo.outer);
    _fill.color = const Color(0xFF000000);
    canvas.drawPath(logo.road, _fill);
    _stroke
      ..color = const Color(0xE6FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.butt;
    canvas.drawPath(logo.edgeLeft, _stroke);
    canvas.drawPath(logo.edgeRight, _stroke);
    _stroke
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = SplashLogoGeometry.dashWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(logo.dashes(_f.phi), _stroke);
    canvas.restore();

    if (_f.wheelVisible) {
      _fill.color = const Color(0xFF000000);
      canvas.drawCircle(SplashLogoGeometry.wheelCenter, SplashLogoGeometry.wheelRadius, _fill);
    }
    canvas.restore();
  }

  // ---------------------------------------------------------------------- tyre
  static const Rect _spriteRect = Rect.fromLTWH(-SplashSprites.tyreUnits / 2, -SplashSprites.tyreUnits / 2,
      SplashSprites.tyreUnits, SplashSprites.tyreUnits);

  void _drawTyre(Canvas canvas, SplashTier tier) {
    final th = _f.thetaDeg * math.pi / 180;
    final sn = math.sin(th), cs = math.max(.001, math.cos(th));
    final w = SplashLayout.treadHalfWidth * sn;
    canvas.save();
    canvas.translate(_f.tyreX, _f.tyreY);
    canvas.scale(_f.tyreScale * _f.squashX, _f.tyreScale * _f.squashY);

    // tread band (one textured mesh) + silhouette edge
    final bandAlpha = clamp01(sn * 14);
    if (bandAlpha > .01) _drawTread(canvas, tier, sn, cs, bandAlpha);

    // near face (rim side), squashed by the viewing angle; not drawn at all in the pure rear view
    if (cs > .02) {
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(cs, 1);
      _fill.color = const Color(0xFF000000);
      canvas.drawCircle(Offset.zero, 100, _fill);
      final da = _f.detailAlpha;
      if (da > .01) {
        _image.color = Color.fromRGBO(255, 255, 255, da);
        final rot = _f.rotDeg * math.pi / 180;
        _drawSprite(canvas, sprites.tyreA, rot);
        _drawSprite(canvas, sprites.caliper, 0);
        _drawSprite(canvas, sprites.tyreB, rot);
        _drawSprite(canvas, sprites.highlights, 0);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawSprite(Canvas canvas, ui.Image img, double rot) {
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    if (rot != 0) {
      canvas.save();
      canvas.rotate(rot);
      canvas.drawImageRect(img, src, _spriteRect, _image);
      canvas.restore();
    } else {
      canvas.drawImageRect(img, src, _spriteRect, _image);
    }
  }

  void _drawTread(Canvas canvas, SplashTier tier, double sn, double cs, double alpha) {
    final mesh = _meshes.putIfAbsent(tier.treadRows, () => _TreadMesh(tier.treadRows));
    final rows = mesh.rows, cols = _TreadMesh.cols;
    const hw = SplashLayout.treadHalfWidth;
    final ra = 2 * hw / (cols - 1);
    final a8 = (alpha * 255).round();
    final edge = Path();
    final nearEdge = Path(); // right / top / bottom outline: only needed when the rim face isn't covering them
    var lastFarX = 0.0, lastY = 0.0;
    for (var r = 0; r < rows; r++) {
      final psiDeg = 90 - 180 * r / (rows - 1);
      final psi = psiDeg * math.pi / 180;
      final cosP = math.cos(psi), y = -100 * math.sin(psi);
      final c1 = math.max(.05, cosP);
      final f = (90 - psiDeg) / 180;
      final overlay = f < .22
          ? lerpD(.72, .18, f / .22)
          : f < .5
              ? lerpD(.18, 0, (f - .22) / .28)
              : f < .78
                  ? lerpD(0, .18, (f - .5) / .28)
                  : lerpD(.18, .72, (f - .78) / .22);
      final shade = (.4 + .6 * c1) * (1 - overlay);
      final g = (shade * 255).round().clamp(0, 255).toInt();
      final color = (a8 << 24) | (g << 16) | (g << 8) | g;
      final v = (psiDeg - _f.rotDeg) * (SplashSprites.treadHeightPx / 360);
      for (var c = 0; c < cols; c++) {
        final a = -hw + c * ra;
        final i = r * cols + c;
        mesh.positions[i * 2] = a * sn - 100 * cs * cosP;
        mesh.positions[i * 2 + 1] = y;
        mesh.texCoords[i * 2] = c * (SplashSprites.treadWidthPx / (cols - 1));
        mesh.texCoords[i * 2 + 1] = v;
        mesh.colors[i] = color;
      }
      final px = -hw * sn - 100 * cs * cosP;
      final nx = hw * sn - 100 * cs * cosP;
      if (r == 0) {
        edge.moveTo(px, y);
        nearEdge
          ..moveTo(px, y)
          ..lineTo(nx, y);
      } else {
        edge.lineTo(px, y);
        nearEdge.lineTo(nx, y);
      }
      lastFarX = px;
      lastY = y;
    }
    nearEdge.lineTo(lastFarX, lastY);
    final verts = ui.Vertices.raw(
      ui.VertexMode.triangles,
      mesh.positions,
      textureCoordinates: mesh.texCoords,
      colors: mesh.colors,
      indices: mesh.indices,
    );
    _meshPaint.shader = treadShader;
    canvas.drawVertices(verts, BlendMode.modulate, _meshPaint);
    verts.dispose();
    _stroke
      ..color = Color.fromRGBO(0, 0, 0, alpha)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(edge, _stroke);
    final outline = clamp01(1 - cs / .15); // fades out as the rim face turns into view
    if (outline > .01) {
      _stroke.color = Color.fromRGBO(0, 0, 0, alpha * outline);
      canvas.drawPath(nearEdge, _stroke);
    }
  }

  // --------------------------------------------------------------------- smoke
  void _drawSmoke(Canvas canvas, double t, SplashTier tier) {
    final n = timeline.smoke(t, _smoke, stride: tier.smokeStride);
    if (n == 0) return;
    canvas.drawRawAtlas(
      sprites.smoke,
      Float32List.sublistView(_smoke.transforms, 0, n * 4),
      Float32List.sublistView(_smoke.rects, 0, n * 4),
      Int32List.sublistView(_smoke.colors, 0, n),
      BlendMode.modulate,
      null,
      _atlas,
    );
  }

  // ------------------------------------------------------------------ wordmark
  void _drawWordmark(Canvas canvas) {
    if (_f.wordAlpha <= .005) return;
    final img = sprites.wordmark;
    const w = SplashLayout.wordWidth;
    final h = w * img.height / img.width;
    final top = SplashLayout.wordBaseline + _f.wordOffset - h * .78;
    _image.color = Color.fromRGBO(255, 255, 255, _f.wordAlpha);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(SplashLayout.wordCx - w / 2, top, w, h),
      _image,
    );
  }

  @override
  bool shouldRepaint(covariant SplashPainter old) => old.sprites != sprites || old.quality != quality;
}

class _TreadMesh {
  _TreadMesh(this.rows)
      : positions = Float32List(rows * cols * 2),
        texCoords = Float32List(rows * cols * 2),
        colors = Int32List(rows * cols),
        indices = _indices(rows);

  static const int cols = 5;
  final int rows;
  final Float32List positions, texCoords;
  final Int32List colors;
  final Uint16List indices;

  static Uint16List _indices(int rows) {
    final out = <int>[];
    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < cols - 1; c++) {
        final a = r * cols + c, b = a + 1, d = a + cols, e = d + 1;
        out.addAll([a, b, d, b, e, d]);
      }
    }
    return Uint16List.fromList(out);
  }
}
