import 'package:dio/dio.dart';
import 'package:fleet_management/core/constants/api_constants.dart';

class CapabilityApi {
  final Dio _dio;

  CapabilityApi(this._dio);

  /// Get all capabilities
  Future<Map<String, dynamic>> getAllCapabilities() async {
    try {
      final response = await _dio.get('${ApiConstants.capabilitiesBaseUrl}');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get capabilities by category
  Future<Map<String, dynamic>> getCapabilitiesByCategory(String category) async {
    try {
      final response = await _dio.get('${ApiConstants.capabilitiesBaseUrl}/category/$category');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get capability categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _dio.get('${ApiConstants.capabilitiesBaseUrl}/categories');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Search capabilities
  Future<Map<String, dynamic>> searchCapabilities(String keyword) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.capabilitiesBaseUrl}/search',
        queryParameters: {'keyword': keyword},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user's capabilities
  Future<Map<String, dynamic>> getMyCapabilities() async {
    try {
      final response = await _dio.get('${ApiConstants.capabilitiesBaseUrl}/user/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user capabilities
  Future<Map<String, dynamic>> getUserCapabilities(String userId, {String? organizationId}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.capabilitiesBaseUrl}/user/$userId',
        queryParameters: organizationId != null ? {'organization_id': organizationId} : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has capability
  Future<Map<String, dynamic>> checkUserCapability(
    String userId,
    String capabilityKey, {
    String requiredLevel = 'view',
    String? organizationId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.capabilitiesBaseUrl}/user/$userId/check/$capabilityKey',
        queryParameters: {
          'required_level': requiredLevel,
          if (organizationId != null) 'organization_id': organizationId,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
