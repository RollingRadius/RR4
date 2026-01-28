import 'package:dio/dio.dart';
import 'package:fleet_management/core/constants/api_constants.dart';

class TemplateApi {
  final Dio _dio;

  TemplateApi(this._dio);

  /// Get all predefined templates
  Future<Map<String, dynamic>> getAllPredefinedTemplates() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/templates/predefined');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get specific predefined template
  Future<Map<String, dynamic>> getPredefinedTemplate(String roleKey) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/templates/predefined/$roleKey');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Merge templates
  Future<Map<String, dynamic>> mergeTemplates(
    List<String> templateKeys,
    String strategy,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/templates/merge',
        data: {
          'template_keys': templateKeys,
          'strategy': strategy,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Compare templates
  Future<Map<String, dynamic>> compareTemplates(List<String> templateKeys) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/templates/compare',
        data: {'template_keys': templateKeys},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get custom templates
  Future<Map<String, dynamic>> getCustomTemplates() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/templates/custom');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get template sources
  Future<Map<String, dynamic>> getTemplateSources(String customRoleId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/templates/custom/$customRoleId/sources');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
