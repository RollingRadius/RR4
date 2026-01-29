import 'package:fleet_management/data/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Organization API Service (for multi-organization management)
class OrganizationApi {
  final ApiService _apiService;

  OrganizationApi(this._apiService);

  /// Get all organizations the user belongs to
  Future<Map<String, dynamic>> getUserOrganizations() async {
    try {
      final response = await _apiService.dio.get(
        '/api/user/organizations',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Switch to a different organization
  Future<Map<String, dynamic>> switchOrganization(String organizationId) async {
    try {
      final response = await _apiService.dio.post(
        '/api/user/set-organization/$organizationId',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

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

  /// Get pending users for an organization
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

  /// Approve a user to join the organization
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

  /// Reject a user's request to join the organization
  Future<Map<String, dynamic>> rejectUser(
    String organizationId,
    String userId,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/api/organizations/$organizationId/reject-user',
        data: {
          'user_id': userId,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update a user's role in the organization
  Future<Map<String, dynamic>> updateUserRole(
    String organizationId,
    String userId,
    String roleKey,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '/api/organizations/$organizationId/members/$userId/role',
        data: {
          'role_key': roleKey,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Remove a user from the organization
  Future<Map<String, dynamic>> removeUser(
    String organizationId,
    String userId,
  ) async {
    try {
      final response = await _apiService.dio.delete(
        '/api/organizations/$organizationId/members/$userId',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}

/// Organization API Provider
final organizationApiProvider = Provider<OrganizationApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return OrganizationApi(apiService);
});
