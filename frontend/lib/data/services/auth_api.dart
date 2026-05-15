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

  /// Get a user's security questions for password recovery
  Future<Map<String, dynamic>> getUserSecurityQuestionsForRecovery(
      String username) async {
    try {
      final response = await _apiService.dio.get(
        '/api/auth/forgot-password/questions/$username',
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Verify security answers and get a password-reset token
  Future<Map<String, dynamic>> verifySecurityAnswers({
    required String username,
    required List<Map<String, String>> answers,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/forgot-password/verify-answers',
        data: {'username': username, 'answers': answers},
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Reset password using the token obtained after answer verification
  Future<Map<String, dynamic>> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/reset-password',
        data: {'reset_token': resetToken, 'new_password': newPassword},
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
