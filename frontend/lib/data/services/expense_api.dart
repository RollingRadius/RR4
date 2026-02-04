import 'package:dio/dio.dart';
import 'package:fleet_management/data/models/expense_model.dart';
import 'package:fleet_management/data/services/api_service.dart';

class ExpenseApi {
  final ApiService _apiService;

  ExpenseApi(this._apiService);

  Dio get _dio => _apiService.dio;

  /// Create a new expense
  Future<ExpenseModel> createExpense(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/expenses', data: data);
      return ExpenseModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get paginated list of expenses
  Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? category,
    String? vehicleId,
    String? driverId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        'skip': (page - 1) * pageSize,
        'limit': pageSize,
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (driverId != null) 'driver_id': driverId,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };

      final response = await _dio.get('/api/expenses', queryParameters: queryParams);

      return {
        'expenses': (response.data['expenses'] as List)
            .map((e) => ExpenseModel.fromJson(e))
            .toList(),
        'total': response.data['total'],
        'page': response.data['page'],
        'page_size': response.data['page_size'],
      };
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get expense by ID
  Future<ExpenseModel> getExpense(String id) async {
    try {
      final response = await _dio.get('/api/expenses/$id');
      return ExpenseModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update expense
  Future<ExpenseModel> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/expenses/$id', data: data);
      return ExpenseModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      await _dio.delete('/api/expenses/$id');
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Submit expense for approval
  Future<ExpenseModel> submitExpense(String id) async {
    try {
      final response = await _dio.post('/api/expenses/$id/submit');
      return ExpenseModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Approve or reject expense
  Future<ExpenseModel> approveExpense(String id, {
    required bool approved,
    String? rejectionReason,
  }) async {
    try {
      final response = await _dio.post(
        '/api/expenses/$id/approve',
        data: {
          'approved': approved,
          if (rejectionReason != null) 'rejection_reason': rejectionReason,
        },
      );
      return ExpenseModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Mark expense as paid
  Future<ExpenseModel> markExpensePaid(String id) async {
    try {
      final response = await _dio.post('/api/expenses/$id/mark-paid');
      return ExpenseModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Upload attachment
  Future<void> uploadAttachment(String id, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await _dio.post('/api/expenses/$id/attachments', data: formData);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// List attachments
  Future<List<ExpenseAttachmentModel>> listAttachments(String id) async {
    try {
      final response = await _dio.get('/api/expenses/$id/attachments');
      return (response.data['attachments'] as List)
          .map((e) => ExpenseAttachmentModel.fromJson(e))
          .toList();
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete attachment
  Future<void> deleteAttachment(String expenseId, String attachmentId) async {
    try {
      await _dio.delete('/api/expenses/$expenseId/attachments/$attachmentId');
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get expense summary by category
  Future<Map<String, dynamic>> getSummaryByCategory({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };
      final response = await _dio.get(
        '/api/expenses/summary/by-category',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get expense summary by vehicle
  Future<Map<String, dynamic>> getSummaryByVehicle({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };
      final response = await _dio.get(
        '/api/expenses/summary/by-vehicle',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get expense summary by month
  Future<Map<String, dynamic>> getSummaryByMonth({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };
      final response = await _dio.get(
        '/api/expenses/summary/by-month',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
