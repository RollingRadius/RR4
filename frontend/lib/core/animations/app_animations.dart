/// Shared animation utilities for Fleet Management app.
///
/// Usage patterns:
///   FadeSlide(delay: 200, child: myWidget)
///   ScaleFade(delay: 100, child: myIcon)
///   StaggeredItem(index: i, child: myCard)
///   PageEntrance(child: myScrollView)
library app_animations;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// FADE + SLIDE FROM BOTTOM  (most common page-entry pattern)
// ─────────────────────────────────────────────────────────────

/// Fades in and slides up from a small offset.
/// [delay] is in milliseconds; [duration] defaults to 500ms.
class FadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;
  final int duration;
  final Offset beginOffset;

  const FadeSlide({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = 500,
    this.beginOffset = const Offset(0, 0.12),
  });

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────
// SCALE + FADE  (icons, avatars, hero elements)
// ─────────────────────────────────────────────────────────────

class ScaleFade extends StatefulWidget {
  final Widget child;
  final int delay;
  final int duration;
  final double beginScale;
  final Curve curve;

  const ScaleFade({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = 500,
    this.beginScale = 0.75,
    this.curve = Curves.easeOutBack,
  });

  @override
  State<ScaleFade> createState() => _ScaleFadeState();
}

class _ScaleFadeState extends State<ScaleFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );
    _scale = Tween<double>(begin: widget.beginScale, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────
// STAGGERED LIST ITEM  (lists, grids, form sections)
// ─────────────────────────────────────────────────────────────

/// Automatically staggers based on [index].
/// Each item delays by [staggerMs] * index milliseconds.
class StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final int staggerMs;
  final int baseDelay;
  final int duration;

  const StaggeredItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerMs = 80,
    this.baseDelay = 0,
    this.duration = 450,
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay =
        widget.baseDelay + widget.staggerMs * widget.index;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────
// PAGE ENTRANCE  (wraps entire scrollable page body)
// ─────────────────────────────────────────────────────────────

/// Simple fade-in for an entire page. Wraps child in FadeTransition.
class PageEntrance extends StatefulWidget {
  final Widget child;
  final int duration;

  const PageEntrance({super.key, required this.child, this.duration = 400});

  @override
  State<PageEntrance> createState() => _PageEntranceState();
}

class _PageEntranceState extends State<PageEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: widget.child);
}

// ─────────────────────────────────────────────────────────────
// PRESS SCALE  (tap feedback for cards / buttons)
// ─────────────────────────────────────────────────────────────

/// Shrinks slightly on press, springs back on release.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleFactor : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHIMMER LOADING PLACEHOLDER
// ─────────────────────────────────────────────────────────────

/// A shimmer placeholder for loading states.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [
                Colors.grey.withOpacity(0.12),
                Colors.grey.withOpacity(0.25),
                Colors.grey.withOpacity(0.12),
              ],
              stops: [
                (_anim.value - 0.4).clamp(0.0, 1.0),
                _anim.value.clamp(0.0, 1.0),
                (_anim.value + 0.4).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
