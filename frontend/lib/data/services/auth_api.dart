import 'package:fleet_management/data/services/api_service.dart';

/// Authentication API Service
class AuthApi {
  final ApiService _apiService;

  AuthApi(this._apiService);

  /// User signup
  Future<Map<String, dynamic>> signup(Map<String, dynamic> signupData) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/signup',
        data: signupData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// User login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Verify email
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/verify-email',
        data: {'token': token},
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Verify email with 6-digit code
  Future<Map<String, dynamic>> verifyEmailCode(String verificationCode) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/verify-email-code',
        data: {'verification_code': verificationCode},
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get security questions
  Future<Map<String, dynamic>> getSecurityQuestions() async {
    try {
      final response = await _apiService.dio.get(
        '/api/auth/security-questions',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
