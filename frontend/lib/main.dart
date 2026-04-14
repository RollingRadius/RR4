import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
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
      // Skip transient network errors (WebSocket reconnects, offline state)
      if (error is SocketException) return true;
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check token expiry when the app comes back from the background.
      // The OS may have suspended the Dart isolate, killing any active Timer.
      ref.read(authProvider.notifier).checkTokenExpiry();
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
    );
  }
}
