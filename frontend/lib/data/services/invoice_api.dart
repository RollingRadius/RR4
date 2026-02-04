import 'package:dio/dio.dart';
import 'package:fleet_management/data/models/invoice_model.dart';
import 'package:fleet_management/data/services/api_service.dart';

class InvoiceApi {
  final ApiService _apiService;

  InvoiceApi(this._apiService);

  Dio get _dio => _apiService.dio;

  /// Create a new invoice
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/invoices', data: data);
      return InvoiceModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get paginated list of invoices
  Future<Map<String, dynamic>> getInvoices({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? customerName,
    String? fromDate,
    String? toDate,
    bool overdueOnly = false,
  }) async {
    try {
      final queryParams = {
        'skip': (page - 1) * pageSize,
        'limit': pageSize,
        if (status != null) 'status': status,
        if (customerName != null) 'customer_name': customerName,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        'overdue_only': overdueOnly,
      };

      final response = await _dio.get('/api/invoices', queryParameters: queryParams);

      return {
        'invoices': (response.data['invoices'] as List)
            .map((e) => InvoiceModel.fromJson(e))
            .toList(),
        'total': response.data['total'],
        'page': response.data['page'],
        'page_size': response.data['page_size'],
      };
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get invoice by ID
  Future<InvoiceModel> getInvoice(String id) async {
    try {
      final response = await _dio.get('/api/invoices/$id');
      return InvoiceModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update invoice
  Future<InvoiceModel> updateInvoice(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/invoices/$id', data: data);
      return InvoiceModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete invoice
  Future<void> deleteInvoice(String id) async {
    try {
      await _dio.delete('/api/invoices/$id');
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Add line item to invoice
  Future<InvoiceLineItemModel> addLineItem(String invoiceId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/invoices/$invoiceId/line-items', data: data);
      return InvoiceLineItemModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update line item
  Future<InvoiceLineItemModel> updateLineItem(
    String invoiceId,
    String lineItemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/invoices/$invoiceId/line-items/$lineItemId',
        data: data,
      );
      return InvoiceLineItemModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete line item
  Future<void> deleteLineItem(String invoiceId, String lineItemId) async {
    try {
      await _dio.delete('/api/invoices/$invoiceId/line-items/$lineItemId');
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Send invoice to customer
  Future<InvoiceModel> sendInvoice(String id, {
    String? recipientEmail,
    List<String>? ccEmails,
    String? customMessage,
  }) async {
    try {
      final response = await _dio.post(
        '/api/invoices/$id/send',
        data: {
          if (recipientEmail != null) 'recipient_email': recipientEmail,
          if (ccEmails != null) 'cc_emails': ccEmails,
          if (customMessage != null) 'custom_message': customMessage,
        },
      );
      return InvoiceModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Record payment for invoice
  Future<InvoiceModel> recordPayment(String id, {
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    String? referenceNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/api/invoices/$id/record-payment',
        data: {
          'amount': amount,
          'payment_date': paymentDate,
          'payment_method': paymentMethod,
          if (referenceNumber != null) 'reference_number': referenceNumber,
        },
      );
      return InvoiceModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Cancel invoice
  Future<InvoiceModel> cancelInvoice(String id) async {
    try {
      final response = await _dio.post('/api/invoices/$id/cancel');
      return InvoiceModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get overdue invoices
  Future<List<InvoiceModel>> getOverdueInvoices() async {
    try {
      final response = await _dio.get('/api/invoices/overdue');
      return (response.data as List)
          .map((e) => InvoiceModel.fromJson(e))
          .toList();
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get invoice summary
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
        '/api/invoices/summary',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
