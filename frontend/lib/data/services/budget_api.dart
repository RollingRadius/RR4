import 'package:dio/dio.dart';
import 'package:fleet_management/data/models/budget_model.dart';
import 'package:fleet_management/data/services/api_service.dart';

class BudgetApi {
  final ApiService _apiService;

  BudgetApi(this._apiService);

  Dio get _dio => _apiService.dio;

  /// Create a new budget
  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/budgets', data: data);
      return BudgetModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get paginated list of budgets
  Future<Map<String, dynamic>> getBudgets({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? period,
    bool activeOnly = false,
  }) async {
    try {
      final queryParams = {
        'skip': (page - 1) * pageSize,
        'limit': pageSize,
        if (category != null) 'category': category,
        if (period != null) 'period': period,
        'active_only': activeOnly,
      };

      final response = await _dio.get('/api/budgets', queryParameters: queryParams);

      return {
        'budgets': (response.data['budgets'] as List)
            .map((e) => BudgetModel.fromJson(e))
            .toList(),
        'total': response.data['total'],
        'page': response.data['page'],
        'page_size': response.data['page_size'],
      };
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get budget by ID
  Future<BudgetModel> getBudget(String id) async {
    try {
      final response = await _dio.get('/api/budgets/$id');
      return BudgetModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update budget
  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/budgets/$id', data: data);
      return BudgetModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete budget
  Future<void> deleteBudget(String id) async {
    try {
      await _dio.delete('/api/budgets/$id');
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get budget summary for dashboard
  Future<Map<String, dynamic>> getSummary({
    bool activeOnly = true,
  }) async {
    try {
      final queryParams = {
        'active_only': activeOnly,
      };
      final response = await _dio.get(
        '/api/budgets/summary',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get budget alerts
  Future<List<BudgetModel>> getAlerts() async {
    try {
      final response = await _dio.get('/api/budgets/alerts');
      return (response.data as List)
          .map((e) => BudgetModel.fromJson(e))
          .toList();
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get active budgets
  Future<List<BudgetModel>> getActiveBudgets() async {
    try {
      final response = await _dio.get('/api/budgets/active');
      return (response.data as List)
          .map((e) => BudgetModel.fromJson(e))
          .toList();
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get budget utilization
  Future<Map<String, dynamic>> getUtilization(String id) async {
    try {
      final response = await _dio.get('/api/budgets/$id/utilization');
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Compare budget periods
  Future<Map<String, dynamic>> comparePeriods({
    required String category,
    required String period1Start,
    required String period1End,
    required String period2Start,
    required String period2End,
  }) async {
    try {
      final queryParams = {
        'category': category,
        'period1_start': period1Start,
        'period1_end': period1End,
        'period2_start': period2Start,
        'period2_end': period2End,
      };
      final response = await _dio.get(
        '/api/budgets/compare',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
