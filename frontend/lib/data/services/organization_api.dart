import 'package:fleet_management/data/services/api_service.dart';

/// Organization Management API Service
class OrganizationApi {
  final ApiService _apiService;

  OrganizationApi(this._apiService);

  /// Get organization members
  Future<Map<String, dynamic>> getOrganizationMembers(
    String organizationId, {
    bool includePending = false,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/organizations/$organizationId/members',
        queryParameters: {
          'include_pending': includePending,
        },
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get pending users
  Future<Map<String, dynamic>> getPendingUsers(String organizationId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/organizations/$organizationId/pending-users',
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Approve a user
  Future<Map<String, dynamic>> approveUser(
    String organizationId,
    String userId,
    String roleKey,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/api/organizations/$organizationId/approve-user',
        data: {
          'user_id': userId,
          'role_key': roleKey,
        },
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Reject a user
  Future<Map<String, dynamic>> rejectUser(
    String organizationId,
    String userId, {
    String? reason,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/organizations/$organizationId/reject-user',
        data: {
          'user_id': userId,
          if (reason != null) 'reason': reason,
        },
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update user role
  Future<Map<String, dynamic>> updateUserRole(
    String organizationId,
    String userId,
    String roleKey,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/api/organizations/$organizationId/update-role',
        data: {
          'user_id': userId,
          'role_key': roleKey,
        },
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Remove user from organization
  Future<Map<String, dynamic>> removeUser(
    String organizationId,
    String userId,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/api/organizations/$organizationId/remove-user',
        data: {
          'user_id': userId,
        },
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
