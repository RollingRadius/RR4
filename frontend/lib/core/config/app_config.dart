/// Application Configuration
/// Centralized configuration for API endpoints and app settings
class AppConfig {
  // API Configuration
  // For web/desktop development, use localhost
  // For mobile device testing on local network, use computer's IP address (e.g., 192.168.1.3)
  // For Android emulator, use 10.0.2.2
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

  static const String apiVersion = '/api';

  // Full API URLs
  static String get authBaseUrl => '$apiBaseUrl$apiVersion/auth';
  static String get companiesBaseUrl => '$apiBaseUrl$apiVersion/companies';

  // App Configuration
  static const String appName = 'Fleet Management System';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

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
