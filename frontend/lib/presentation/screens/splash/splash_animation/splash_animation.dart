import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'splash_logo_geometry.dart';
import 'splash_painter.dart';
import 'splash_quality.dart';
import 'splash_sprites.dart';
import 'splash_timeline.dart';

/// The animated RollingRadius splash (tyre runs up the road, road + tyre become the logo).
///
/// - Time-driven: a slow phone drops frames but the animation still ends on time.
/// - Loads its pre-baked sprites first; if that fails it calls [onUnavailable] so the
///   caller can show the plain logo instead.
/// - Calls [onStarted] when the first frame is about to play, with the minimum time the
///   splash should stay on screen.
class SplashAnimation extends StatefulWidget {
  const SplashAnimation({super.key, required this.onStarted, required this.onUnavailable});

  final void Function(Duration minDuration) onStarted;
  final VoidCallback onUnavailable;

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  final SplashTimeline _timeline = SplashTimeline();
  final SplashLogoGeometry _logo = SplashLogoGeometry();
  // Always full quality on every device (owner's decision); the step-down logic stays available but off.
  final SplashQualityMonitor _quality = SplashQualityMonitor(adaptive: false);
  late final Ticker _ticker;
  bool _fallbackRequested = false;
  SplashSprites? _sprites;
  ui.ImageShader? _treadShader;
  ui.Image? _treadImage; // the shader's own handle on the tread texture (see dispose)

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _load();
  }

  Future<void> _load() async {
    try {
      final sprites = await SplashSprites.load();
      if (!mounted) {
        sprites.dispose();
        return;
      }
      _sprites = sprites;
      _treadImage = sprites.tread.clone();
      _treadShader = ui.ImageShader(
        _treadImage!,
        TileMode.clamp,
        TileMode.repeated,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      );
      setState(() {});
      _start();
    } catch (e, st) {
      debugPrint('SplashAnimation: sprites unavailable, using fallback: $e\n$st');
      if (mounted) widget.onUnavailable();
    }
  }

  void _onPaintError(Object error, StackTrace stack) {
    debugPrint('SplashAnimation: painting failed, falling back to the plain logo: $error\n$stack');
    if (_fallbackRequested) return;
    _fallbackRequested = true;
    _ticker.stop();
    // never touch the tree while painting: hand over after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onUnavailable();
    });
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Accessibility "reduce motion": show the finished logo, no animation.
      _clock.value = SplashTiming.totalMs;
      widget.onStarted(const Duration(milliseconds: 600));
      return;
    }
    _quality.attach();
    _ticker.start();
    widget.onStarted(Duration(milliseconds: SplashTiming.totalMs.round()));
  }

  void _onTick(Duration elapsed) {
    final ms = elapsed.inMicroseconds / 1000.0;
    if (ms >= SplashTiming.totalMs) {
      _clock.value = SplashTiming.totalMs;
      _ticker.stop();
      _quality.detach();
    } else {
      _clock.value = ms;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _quality.detach();
    _treadShader?.dispose();
    // Web (CanvasKit) shaders take ownership of the image they were built from and dispose it
    // with the shader; native shaders only keep a native reference and leave the handle to us.
    if (!kIsWeb) _treadImage?.dispose();
    _sprites?.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sprites = _sprites, shader = _treadShader;
    return ColoredBox(
      color: Colors.white,
      child: (sprites == null || shader == null)
          ? const SizedBox.expand()
          : RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: SplashPainter(
                  clock: _clock,
                  sprites: sprites,
                  treadShader: shader,
                  timeline: _timeline,
                  quality: _quality,
                  logo: _logo,
                  onError: _onPaintError,
                ),
              ),
            ),
    );
  }
}
