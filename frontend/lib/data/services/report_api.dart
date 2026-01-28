import 'package:fleet_management/data/services/api_service.dart';

/// Report API Service
class ReportApi {
  final ApiService _apiService;

  ReportApi(this._apiService);

  /// Get driver list report
  Future<Map<String, dynamic>> getDriverListReport({String? statusFilter}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (statusFilter != null) {
        queryParams['status_filter'] = statusFilter;
      }

      final response = await _apiService.dio.get(
        '/api/reports/driver-list',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get license expiry report
  Future<Map<String, dynamic>> getLicenseExpiryReport({int daysAhead = 90}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/reports/license-expiry',
        queryParameters: {'days_ahead': daysAhead},
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get organization summary report
  Future<Map<String, dynamic>> getOrganizationSummaryReport() async {
    try {
      final response = await _apiService.dio.get(
        '/api/reports/organization-summary',
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get audit log report
  Future<Map<String, dynamic>> getAuditLogReport({
    DateTime? startDate,
    DateTime? endDate,
    String? actionFilter,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (actionFilter != null && actionFilter.isNotEmpty) {
        queryParams['action_filter'] = actionFilter;
      }

      final response = await _apiService.dio.get(
        '/api/reports/audit-log',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get user activity report
  Future<Map<String, dynamic>> getUserActivityReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiService.dio.get(
        '/api/reports/user-activity',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
