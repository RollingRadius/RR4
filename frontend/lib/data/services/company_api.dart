import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/data/models/company_model.dart';

/// Company API Service
class CompanyApi {
  final ApiService _apiService;

  CompanyApi(this._apiService);

  /// Search companies
  Future<List<CompanyModel>> searchCompanies(String query) async {
    try {
      final response = await _apiService.dio.get(
        '/api/auth/companies/search',
        queryParameters: {
          'q': query,
          'limit': 3,
        },
      );

      final List<dynamic> companiesJson = response.data['companies'];
      return companiesJson
          .map((json) => CompanyModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Validate company details (GSTIN, PAN)
  Future<Map<String, dynamic>> validateCompanyDetails({
    String? gstin,
    String? panNumber,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/companies/validate',
        data: {
          if (gstin != null) 'gstin': gstin,
          if (panNumber != null) 'pan_number': panNumber,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Create company during signup (no authentication required)
  Future<Map<String, dynamic>> createCompanySignup(
      Map<String, dynamic> companyData) async {
    try {
      final response = await _apiService.dio.post(
        '/api/auth/companies',
        data: companyData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Create company for authenticated users
  Future<Map<String, dynamic>> createCompany(
      Map<String, dynamic> companyData) async {
    try {
      final response = await _apiService.dio.post(
        '/api/companies/create',
        data: companyData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
