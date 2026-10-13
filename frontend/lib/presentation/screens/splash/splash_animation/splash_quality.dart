import 'package:flutter/scheduler.dart';

/// How much work the splash does per frame. Starts at [full] and only ever steps down
/// (never back up, so it can't flicker) when real frame times say the device is struggling.
enum SplashTier {
  full(smokeStride: 1, trails: true, specks: 90, reflectors: true, shadow: true, treadRows: 25),
  medium(smokeStride: 2, trails: false, specks: 40, reflectors: true, shadow: true, treadRows: 19),
  light(smokeStride: 3, trails: false, specks: 0, reflectors: false, shadow: false, treadRows: 13);

  const SplashTier({
    required this.smokeStride,
    required this.trails,
    required this.specks,
    required this.reflectors,
    required this.shadow,
    required this.treadRows,
  });

  final int smokeStride; // draw every Nth smoke puff
  final bool trails; // perspective speed trails around the tyre
  final int specks; // asphalt speckles on the perspective road
  final bool reflectors; // edge reflectors
  final bool shadow;
  final int treadRows; // mesh rows of the tread band

  SplashTier? get next => index + 1 < SplashTier.values.length ? SplashTier.values[index + 1] : null;
}

/// Watches real frame timings (build + raster) and lowers the tier when frames run long.
class SplashQualityMonitor {
  SplashQualityMonitor({SplashTier? initial, this.adaptive = true})
      : tier = initial ?? debugForcedTier ?? SplashTier.full;

  /// When false the tier never changes: the splash always plays at the tier it started with.
  /// (The shipped splash uses false = always full quality, by the owner's decision.)
  final bool adaptive;

  /// QA switch: set before the splash starts to force a tier (e.g. to compare on a real phone).
  static SplashTier? debugForcedTier;

  static const double _budgetMs = 14; // average frame work above this => step down
  static const double _spikeMs = 45; // a single frame this slow => step down
  static const int _warmup = 3; // ignore the first frames (decode / first draw of each type)
  static const int _cooldown = 8; // frames to wait after a step before judging again

  SplashTier tier;
  double averageMs = 0;
  int _frames = 0, _wait = 0;
  bool _attached = false;

  void attach() {
    if (_attached || !adaptive || debugForcedTier != null) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      report(t.totalSpan.inMicroseconds / 1000.0);
    }
  }

  /// Feeds one frame's total work time (ms). Public so tests can drive it without a real GPU.
  void report(double ms) {
    if (!adaptive) return;
    _frames++;
    if (_frames <= _warmup) return;
    averageMs = averageMs == 0 ? ms : averageMs * .7 + ms * .3;
    if (_wait > 0) {
      _wait--;
      return;
    }
    if (averageMs > _budgetMs || ms > _spikeMs) {
      final n = tier.next;
      if (n != null) {
        tier = n;
        _wait = _cooldown;
        averageMs = 0;
      }
    }
  }
}
