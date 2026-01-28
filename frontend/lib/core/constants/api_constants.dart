/// API Constants
/// Centralized API endpoint constants
import 'package:fleet_management/core/config/app_config.dart';

class ApiConstants {
  // Base URL
  static String get baseUrl => AppConfig.apiBaseUrl;

  // API Version
  static const String apiVersion = '/api';

  // Full Base URL with version
  static String get baseApiUrl => '$baseUrl$apiVersion';

  // Authentication Endpoints
  static String get authBaseUrl => '$baseApiUrl/auth';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Company Endpoints
  static String get companiesBaseUrl => '$baseApiUrl/companies';
  static const String searchCompanies = '/search';
  static const String validateCompany = '/validate';
  static const String createCompany = '/create';

  // Driver Endpoints
  static String get driversBaseUrl => '$baseApiUrl/drivers';

  // Vehicle Endpoints
  static String get vehiclesBaseUrl => '$baseApiUrl/vehicles';

  // User Endpoints
  static String get userBaseUrl => '$baseApiUrl/user';

  // Organization Endpoints
  static String get organizationsBaseUrl => '$baseApiUrl/organizations';

  // Reports Endpoints
  static String get reportsBaseUrl => '$baseApiUrl/reports';

  // Capabilities Endpoints
  static String get capabilitiesBaseUrl => '$baseApiUrl/capabilities';

  // Custom Roles Endpoints
  static String get customRolesBaseUrl => '$baseApiUrl/custom-roles';

  // Templates Endpoints
  static String get templatesBaseUrl => '$baseApiUrl/templates';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}
