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
}
