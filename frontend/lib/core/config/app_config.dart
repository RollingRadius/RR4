/// Application Configuration
/// Centralized configuration for API endpoints and app settings
import 'package:fleet_management/core/config/server_config.dart';

class AppConfig {
  // API Configuration — switch server in server_config.dart
  static String get apiBaseUrl => ServerConfig.baseUrl;

  static const String apiVersion = '/api';

  // Full API URLs
  static String get authBaseUrl => '$apiBaseUrl$apiVersion/auth';
  static String get companiesBaseUrl => '$apiBaseUrl$apiVersion/companies';

  // App Configuration
  static const String appName = 'Fleet Management System';
  static const String appVersion = '1.0.0';

  // LocationIQ – autocomplete for pickup / drop locations
  // Replace with your actual token from https://my.locationiq.com/dashboard
  static const String locationIqKey = 'pk.9ab1b6a54c6e760146bdefcc9b6f7e91';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';

  // Validation
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 50;
  static const int passwordMinLength = 8;
  static const int companySearchMinLength = 3;
  static const int companySearchMaxResults = 3;

  // Initialize app configuration
  static void initialize() {
    // Any initialization logic here
    print('App initialized: $appName v$appVersion');
    print('API Base URL: $apiBaseUrl');
  }
}
