import 'package:fleet_management/data/services/api_service.dart';

/// User Profile and Organization API Service
class UserApi {
  final ApiService _apiService;

  UserApi(this._apiService);

  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.dio.get('/api/user/me');
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get user's organizations
  Future<List<Map<String, dynamic>>> getUserOrganizations() async {
    try {
      final response = await _apiService.dio.get('/api/user/organizations');
      final List<dynamic> organizations = response.data['organizations'];
      return organizations.cast<Map<String, dynamic>>();
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Set active organization
  Future<Map<String, dynamic>> setActiveOrganization(String organizationId) async {
    try {
      final response = await _apiService.dio.post(
        '/api/user/set-organization/$organizationId',
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Refresh JWT token with updated user context
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await _apiService.dio.post('/api/user/refresh-token');
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
