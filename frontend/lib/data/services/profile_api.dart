import 'package:dio/dio.dart';
import 'package:fleet_management/data/services/api_service.dart';

/// Profile API Service
class ProfileApi {
  final ApiService _apiService;

  ProfileApi(this._apiService);

  /// Get profile status
  Future<Map<String, dynamic>> getProfileStatus() async {
    try {
      final response = await _apiService.dio.get(
        '/api/profile/status',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Complete profile
  Future<Map<String, dynamic>> completeProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.dio.post(
        '/api/profile/complete',
        data: profileData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Change user role (for Independent Users only)
  Future<Map<String, dynamic>> changeRole(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.dio.post(
        '/api/profile/change-role',
        data: profileData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update user profile information
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.dio.put(
        '/api/profile/update',
        data: profileData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Upload (or replace) the current user's profile picture
  Future<Map<String, dynamic>> uploadProfilePicture(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'picture': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.dio.post(
        '/api/profile/picture',
        data: formData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Remove the current user's profile picture
  Future<Map<String, dynamic>> deleteProfilePicture() async {
    try {
      final response = await _apiService.dio.delete('/api/profile/picture');
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Change the current user's password by re-verifying their security
  /// question answers. Only works for accounts registered with security
  /// questions (not email-authenticated accounts).
  Future<Map<String, dynamic>> changePassword({
    required List<Map<String, String>> answers,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/profile/change-password',
        data: {
          'answers': answers,
          'new_password': newPassword,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
