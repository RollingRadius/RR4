// Dev-only preview of the real animated splash (not part of the app).
//   flutter run -d chrome -t tool/splash_preview/main.dart
// Replay / pause / scrub the timeline, slow it down, or force a quality tier.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_logo_geometry.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_painter.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_quality.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_sprites.dart';
import 'package:fleet_management/presentation/screens/splash/splash_animation/splash_timeline.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: _Preview()));

class _Preview extends StatefulWidget {
  const _Preview();

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  final SplashTimeline _timeline = SplashTimeline();
  final SplashLogoGeometry _logo = SplashLogoGeometry();
  late final Ticker _ticker;
  SplashSprites? _sprites;
  ui.Image? _treadImage;
  ui.ImageShader? _shader;
  SplashQualityMonitor _quality = SplashQualityMonitor(initial: SplashTier.full);
  SplashTier _tier = SplashTier.full;
  double _speed = 1, _offset = 0;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _load();
  }

  Future<void> _load() async {
    final s = await SplashSprites.load();
    if (!mounted) {
      s.dispose();
      return;
    }
    _treadImage = s.tread.clone();
    _shader = ui.ImageShader(_treadImage!, TileMode.clamp, TileMode.repeated, Matrix4.identity().storage,
        filterQuality: FilterQuality.medium);
    setState(() => _sprites = s);
    _replay();
  }

  void _onTick(Duration e) {
    final ms = e.inMicroseconds / 1000.0 * _speed + _offset;
    if (ms >= SplashTiming.totalMs) {
      _clock.value = SplashTiming.totalMs;
      _ticker.stop();
      setState(() => _playing = false);
    } else {
      _clock.value = ms;
    }
  }

  void _replay() {
    _ticker.stop();
    _offset = 0;
    _clock.value = 0;
    _ticker.start();
    setState(() => _playing = true);
  }

  void _togglePause() {
    if (_playing) {
      _offset = _clock.value;
      _ticker.stop();
      setState(() => _playing = false);
    } else {
      if (_clock.value >= SplashTiming.totalMs) return _replay();
      _offset = _clock.value;
      _ticker.stop();
      _ticker.start();
      setState(() => _playing = true);
    }
  }

  void _scrub(double v) {
    _ticker.stop();
    _clock.value = v;
    _offset = v;
    if (_playing) setState(() => _playing = false);
  }

  void _setSpeed(double s) {
    _offset = _clock.value;
    if (_playing) {
      _ticker.stop();
      _ticker.start();
    }
    setState(() => _speed = s);
  }

  void _setTier(SplashTier t) => setState(() {
        _tier = t;
        _quality = SplashQualityMonitor(initial: t);
      });

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    if (!kIsWeb) _treadImage?.dispose();
    _sprites?.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sprites = _sprites, shader = _shader;
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 360 / 640,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black26)]),
                    child: ClipRect(
                      child: (sprites == null || shader == null)
                          ? const Center(child: CircularProgressIndicator())
                          : CustomPaint(
                              size: Size.infinite,
                              painter: SplashPainter(
                                  clock: _clock, sprites: sprites, treadShader: shader, timeline: _timeline,
                                  quality: _quality, logo: _logo),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _clock,
                    builder: (_, v, __) => Row(children: [
                      FilledButton.icon(onPressed: _replay, icon: const Icon(Icons.replay), label: const Text('Replay')),
                      const SizedBox(width: 8),
                      IconButton(onPressed: _togglePause, icon: Icon(_playing ? Icons.pause : Icons.play_arrow)),
                      Expanded(
                        child: Slider(value: v.clamp(0, SplashTiming.totalMs), min: 0, max: SplashTiming.totalMs, onChanged: _scrub),
                      ),
                      SizedBox(width: 78, child: Text('${v.round()} ms', textAlign: TextAlign.end)),
                    ]),
                  ),
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    const Text('Speed'),
                    for (final s in const [1.0, 0.5, 0.25])
                      ChoiceChip(label: Text('${s}x'), selected: _speed == s, onSelected: (_) => _setSpeed(s)),
                    const SizedBox(width: 12),
                    const Text('Quality'),
                    for (final t in SplashTier.values)
                      ChoiceChip(label: Text(t.name), selected: _tier == t, onSelected: (_) => _setTier(t)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
