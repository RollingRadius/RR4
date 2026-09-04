import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/data/services/analytics_service.dart';
import 'package:fleet_management/data/services/fcm_service.dart';
import 'package:fleet_management/data/services/remote_config_service.dart';
import 'package:fleet_management/routes/app_router.dart';
import 'package:fleet_management/providers/settings_provider.dart';
import 'package:fleet_management/providers/theme_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';

/// App-wide ScaffoldMessenger — outlives any single screen's own Scaffold.
/// A SnackBar shown via a screen-local `ScaffoldMessenger.of(context)`
/// immediately followed by `context.go(...)` (a full route REPLACE, not a
/// push) gets torn down mid-animation along with that screen's Scaffold —
/// the orphaned SnackBar then throws "No Material widget found" and a
/// nonsensical giant RenderFlex overflow on its remaining animation frames
/// (confirmed root cause of a live crash right after driver login/profile
/// completion navigating to the dashboard). Routing SnackBars through this
/// key instead means they're anchored to the whole app, not whichever
/// screen happens to be getting replaced underneath them.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Android/iOS only — not web)
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Crashlytics — forward all Flutter + async errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      // Skip transient network/WebSocket errors — these are handled by reconnect logic
      if (error is SocketException) return true;
      if (error is WebSocketChannelException) return true;
      if (error.toString().contains('HandshakeException')) return true;
      if (error.toString().contains('WebSocketException')) return true;
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // FCM — request permission and set up foreground notification display
    await FcmService().initialize();

    // Remote Config — fetch latest values in background
    await RemoteConfigService().initialize();

    // Analytics — ready for use via AnalyticsService()
    AnalyticsService();
  }

  // Initialize app configuration
  AppConfig.initialize();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FleetManagementApp(),
    ),
  );
}

class FleetManagementApp extends ConsumerStatefulWidget {
  const FleetManagementApp({super.key});

  @override
  ConsumerState<FleetManagementApp> createState() => _FleetManagementAppState();
}

class _FleetManagementAppState extends ConsumerState<FleetManagementApp>
    with WidgetsBindingObserver {
  // Track whether the app was truly backgrounded (paused). On Android, showing
  // a keyboard or in-app dialog triggers inactive→resumed WITHOUT going through
  // paused. We only want to run checkTokenExpiry on a real background→foreground
  // transition, not on every keyboard dismiss.
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Best-effort instant refresh on reassignment (see FcmService and
    // driver_link_service.py:_nudge_driver_refresh) — same reaction as the
    // app-resume lifecycle hook below, just triggered by a silent push
    // instead of a background→foreground transition. No-op for non-drivers,
    // and harmless if the push never arrives — the periodic poll is unaffected.
    FcmService.onTripReassignedNudge = () {
      final user = ref.read(authProvider).user;
      if (user?.isDriver != true) return;
      ref.read(tripProvider.notifier).silentRefresh().then((_) {
        if (mounted) syncDriverTrackingToActiveTrip(ref);
      });
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FcmService.onTripReassignedNudge = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    }
    if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      // Re-check token expiry only when returning from a true background pause.
      // The OS may have suspended the Dart isolate, killing any active Timer.
      ref.read(authProvider.notifier).checkTokenExpiry();

      // Same "true background→foreground only" reasoning applies to
      // tracking: the OS may have paused the position stream/timers, so a
      // driver's trip assignment could have changed while backgrounded —
      // re-sync once resumed. No-op for every other role.
      final user = ref.read(authProvider).user;
      if (user?.isDriver == true) {
        ref.read(tripProvider.notifier).silentRefresh().then((_) {
          if (mounted) syncDriverTrackingToActiveTrip(ref);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Fleet Management System',
      debugShowCheckedModeBanner: false,
      theme: themeState.themeData, // Dynamic theme from branding
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
