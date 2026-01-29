import 'package:fleet_management/data/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Organization Dashboard API Service (for owner dashboard)
class OrganizationDashboardApi {
  final ApiService _apiService;

  OrganizationDashboardApi(this._apiService);

  /// Get my organization details with statistics
  Future<Map<String, dynamic>> getMyOrganization() async {
    try {
      final response = await _apiService.dio.get(
        '/api/organization/my-organization',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get all employees
  Future<Map<String, dynamic>> getEmployees({
    String? roleFilter,
    String statusFilter = 'active',
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/organization/employees',
        queryParameters: {
          if (roleFilter != null) 'role_filter': roleFilter,
          'status_filter': statusFilter,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update employee role
  Future<Map<String, dynamic>> updateEmployeeRole(
    String userOrgId,
    String newRoleId,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '/api/organization/employees/$userOrgId/role',
        queryParameters: {
          'new_role_id': newRoleId,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Remove employee
  Future<Map<String, dynamic>> removeEmployee(String userOrgId) async {
    try {
      final response = await _apiService.dio.delete(
        '/api/organization/employees/$userOrgId',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get organization statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _apiService.dio.get(
        '/api/organization/statistics',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}

/// Organization Dashboard API Provider
final organizationDashboardApiProvider = Provider<OrganizationDashboardApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return OrganizationDashboardApi(apiService);
});
