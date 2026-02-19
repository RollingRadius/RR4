import 'package:dio/dio.dart';
import 'package:fleet_management/core/constants/api_constants.dart';

class CustomRoleApi {
  final Dio _dio;

  CustomRoleApi(this._dio);

  /// Get all custom roles
  Future<Map<String, dynamic>> getAllCustomRoles({bool includeTemplates = false}) async {
    try {
      final response = await _dio.get(
        ApiConstants.customRolesBaseUrl,
        queryParameters: {'include_templates': includeTemplates},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create custom role from scratch
  Future<Map<String, dynamic>> createCustomRole({
    required String roleName,
    String? description,
    required Map<String, String> capabilities,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.customRolesBaseUrl,
        data: {
          'role_name': roleName,
          'description': description,
          'capabilities': capabilities,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create custom role from template
  Future<Map<String, dynamic>> createFromTemplate({
    required String roleName,
    required List<String> templateKeys,
    String? description,
    Map<String, String>? customizations,
    String mergeStrategy = 'union',
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.customRolesBaseUrl}/from-template',
        data: {
          'role_name': roleName,
          'template_keys': templateKeys,
          'description': description,
          'customizations': customizations,
          'merge_strategy': mergeStrategy,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get custom role details
  Future<Map<String, dynamic>> getCustomRole(String customRoleId) async {
    try {
      final response = await _dio.get('${ApiConstants.customRolesBaseUrl}/$customRoleId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Update custom role
  Future<Map<String, dynamic>> updateCustomRole(
    String customRoleId, {
    String? roleName,
    String? description,
    Map<String, String>? capabilities,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.customRolesBaseUrl}/$customRoleId',
        data: {
          if (roleName != null) 'role_name': roleName,
          if (description != null) 'description': description,
          if (capabilities != null) 'capabilities': capabilities,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete custom role
  Future<Map<String, dynamic>> deleteCustomRole(String customRoleId) async {
    try {
      final response = await _dio.delete('${ApiConstants.customRolesBaseUrl}/$customRoleId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Clone custom role
  Future<Map<String, dynamic>> cloneCustomRole(String customRoleId, String newRoleName) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.customRolesBaseUrl}/$customRoleId/clone',
        data: {'new_role_name': newRoleName},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get role capabilities
  Future<Map<String, dynamic>> getRoleCapabilities(String customRoleId) async {
    try {
      final response = await _dio.get('${ApiConstants.customRolesBaseUrl}/$customRoleId/capabilities');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Add capability to role
  Future<Map<String, dynamic>> addCapability(
    String customRoleId,
    String capabilityKey,
    String accessLevel, {
    Map<String, dynamic>? constraints,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.customRolesBaseUrl}/$customRoleId/capabilities',
        data: {
          'capability_key': capabilityKey,
          'access_level': accessLevel,
          if (constraints != null) 'constraints': constraints,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove capability from role
  Future<Map<String, dynamic>> removeCapability(String customRoleId, String capabilityKey) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.customRolesBaseUrl}/$customRoleId/capabilities/$capabilityKey',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk update capabilities
  Future<Map<String, dynamic>> bulkUpdateCapabilities(
    String customRoleId,
    List<Map<String, dynamic>> capabilities,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.customRolesBaseUrl}/$customRoleId/capabilities/bulk',
        data: {'capabilities': capabilities},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get impact analysis
  Future<Map<String, dynamic>> getImpactAnalysis(String customRoleId) async {
    try {
      final response = await _dio.get('${ApiConstants.customRolesBaseUrl}/$customRoleId/impact-analysis');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Save as template
  Future<Map<String, dynamic>> saveAsTemplate(
    String customRoleId,
    String templateName, {
    String? templateDescription,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.customRolesBaseUrl}/$customRoleId/save-as-template',
        data: {
          'template_name': templateName,
          if (templateDescription != null) 'template_description': templateDescription,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
