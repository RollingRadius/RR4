import 'package:dio/dio.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/data/models/receiving_document_model.dart';

/// Receiving Docs API — one uploaded image tagged with a date.
class ReceivingDocumentApi {
  final ApiService _apiService;

  ReceivingDocumentApi(this._apiService);

  /// Upload one receiving-sheet image tagged with [docDate] (yyyy-MM-dd).
  Future<ReceivingDocumentModel> upload({
    required List<int> fileBytes,
    required String fileName,
    required String docDate,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'doc_date': docDate,
      });
      final response = await _apiService.dio.post('/api/receiving-documents', data: formData);
      return ReceivingDocumentModel.fromJson(
          (response.data as Map<String, dynamic>)['document'] as Map<String, dynamic>);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Paginated list of past uploads for the current org, newest first.
  /// [docDate] (yyyy-MM-dd), when given, only returns docs tagged with that day.
  Future<Map<String, dynamic>> list({int skip = 0, int limit = 50, String? docDate}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/receiving-documents',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (docDate != null && docDate.trim().isNotEmpty) 'doc_date': docDate.trim(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
