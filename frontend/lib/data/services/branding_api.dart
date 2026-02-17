import 'package:dio/dio.dart';
import 'package:fleet_management/data/models/branding_model.dart';
import 'package:fleet_management/data/services/api_service.dart';

class BrandingApi {
  final ApiService _apiService;

  BrandingApi(this._apiService);

  Dio get _dio => _apiService.dio;

  /// Get organization branding
  Future<OrganizationBranding> getBranding() async {
    try {
      final response = await _dio.get('/api/v1/branding');
      return OrganizationBranding.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update branding colors and theme config
  Future<OrganizationBranding> updateBranding({
    BrandingColors? colors,
    Map<String, dynamic>? themeConfig,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (colors != null) {
        data['colors'] = colors.toJson();
      }

      if (themeConfig != null) {
        data['theme_config'] = themeConfig;
      }

      final response = await _dio.put('/api/v1/branding', data: data);
      return OrganizationBranding.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Upload organization logo
  Future<Map<String, dynamic>> uploadLogo(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/api/v1/branding/logo',
        data: formData,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete organization logo
  Future<Map<String, dynamic>> deleteLogo() async {
    try {
      final response = await _dio.delete('/api/v1/branding/logo');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
