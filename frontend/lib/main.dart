import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/routes/app_router.dart';
import 'package:fleet_management/providers/settings_provider.dart';
import 'package:fleet_management/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

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

class FleetManagementApp extends ConsumerWidget {
  const FleetManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
