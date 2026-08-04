import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/routing/dashboard_route.dart';
import 'package:fleet_management/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _minTimeElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // The logo shows for at least 1.5s regardless of how fast/slow auth
    // resolves — actual navigation only happens once we know whether a
    // session exists (never guessed, never a premature bounce to login
    // while a silent restore is still in flight on a slow connection).
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _minTimeElapsed = true;
      _maybeNavigate();
    });
  }

  void _maybeNavigate() {
    if (_navigated || !mounted || !_minTimeElapsed) return;
    final auth = ref.read(authProvider);
    if (!auth.isInitialized) return; // retried by the ref.listen below once it resolves

    _navigated = true;
    if (!auth.isAuthenticated || auth.user == null) {
      context.go(AppConstants.routeLogin);
      return;
    }
    final user = auth.user!;
    if (!user.profileCompleted) {
      context.go('/profile-complete');
      return;
    }
    context.go(dashboardRouteFor(user));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If auth was still restoring (e.g. a slow refresh-token exchange) when
    // the minimum time elapsed, this fires _maybeNavigate again the moment
    // isInitialized flips true, instead of ever guessing early.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isInitialized && !(previous?.isInitialized ?? false)) {
        _maybeNavigate();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Image.asset(
                  'assest/images/app-logo-with-name.png',
                  width: 220,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
