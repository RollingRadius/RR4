import 'package:dio/dio.dart';
import 'package:fleet_management/data/models/payment_model.dart';
import 'package:fleet_management/data/services/api_service.dart';

class PaymentApi {
  final ApiService _apiService;

  PaymentApi(this._apiService);

  Dio get _dio => _apiService.dio;

  /// Create a new payment
  Future<PaymentModel> createPayment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/payments', data: data);
      return PaymentModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get paginated list of payments
  Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int pageSize = 20,
    String? paymentType,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        'skip': (page - 1) * pageSize,
        'limit': pageSize,
        if (paymentType != null) 'payment_type': paymentType,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };

      final response = await _dio.get('/api/payments', queryParameters: queryParams);

      return {
        'payments': (response.data['payments'] as List)
            .map((e) => PaymentModel.fromJson(e))
            .toList(),
        'total': response.data['total'],
        'page': response.data['page'],
        'page_size': response.data['page_size'],
      };
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get payment by ID
  Future<PaymentModel> getPayment(String id) async {
    try {
      final response = await _dio.get('/api/payments/$id');
      return PaymentModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update payment
  Future<PaymentModel> updatePayment(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/payments/$id', data: data);
      return PaymentModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete payment
  Future<void> deletePayment(String id) async {
    try {
      await _dio.delete('/api/payments/$id');
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get payment summary
  Future<Map<String, dynamic>> getSummary({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };
      final response = await _dio.get(
        '/api/payments/summary',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get payments by method
  Future<Map<String, dynamic>> getPaymentsByMethod({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };
      final response = await _dio.get(
        '/api/payments/by-method',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get payments by period
  Future<Map<String, dynamic>> getPaymentsByPeriod({
    String period = 'monthly',
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = {
        'period': period,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };
      final response = await _dio.get(
        '/api/payments/by-period',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
