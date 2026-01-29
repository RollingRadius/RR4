import 'package:fleet_management/data/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Role API Service
class RoleApi {
  final ApiService _apiService;

  RoleApi(this._apiService);

  /// Get available roles for selection
  Future<Map<String, dynamic>> getAvailableRoles() async {
    try {
      final response = await _apiService.dio.get(
        '/api/roles/available',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get current user's role information
  Future<Map<String, dynamic>> getMyRole() async {
    try {
      final response = await _apiService.dio.get(
        '/api/roles/my-role',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get pending role requests (for owners)
  Future<Map<String, dynamic>> getPendingRoleRequests() async {
    try {
      final response = await _apiService.dio.get(
        '/api/roles/pending-requests',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Approve a role request
  Future<Map<String, dynamic>> approveRoleRequest(
    String userOrgId, {
    String? approvedRoleId,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/roles/approve-request/$userOrgId',
        queryParameters: approvedRoleId != null
            ? {'approved_role_id': approvedRoleId}
            : null,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Reject a role request
  Future<Map<String, dynamic>> rejectRoleRequest(String userOrgId) async {
    try {
      final response = await _apiService.dio.post(
        '/api/roles/reject-request/$userOrgId',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}

/// Role API Provider
final roleApiProvider = Provider<RoleApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RoleApi(apiService);
});
