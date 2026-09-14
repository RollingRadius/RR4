import 'package:dio/dio.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/data/models/receiving_document_model.dart';

/// Receiving Docs API — one uploaded image linked to multiple trips.
class ReceivingDocumentApi {
  final ApiService _apiService;

  ReceivingDocumentApi(this._apiService);

  /// Upload one receiving-sheet image and link it to every id in [tripIds].
  Future<ReceivingDocumentModel> upload({
    required List<int> fileBytes,
    required String fileName,
    required List<String> tripIds,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'trip_ids': tripIds.join(','),
      });
      final response = await _apiService.dio.post('/api/receiving-documents', data: formData);
      return ReceivingDocumentModel.fromJson(
          (response.data as Map<String, dynamic>)['document'] as Map<String, dynamic>);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// The receiving document linked to [tripId], if any.
  Future<ReceivingDocumentModel?> getByTrip(String tripId) async {
    try {
      final response = await _apiService.dio.get('/api/receiving-documents/by-trip/$tripId');
      final data = response.data as Map<String, dynamic>;
      if (data['linked'] != true) return null;
      return ReceivingDocumentModel.fromJson(data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Link additional trips to an already-uploaded document.
  Future<ReceivingDocumentModel> addTrips({
    required String documentId,
    required List<String> tripIds,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/receiving-documents/$documentId/trips',
        data: {'trip_ids': tripIds},
      );
      return ReceivingDocumentModel.fromJson(
          (response.data as Map<String, dynamic>)['document'] as Map<String, dynamic>);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Unlink one trip from a document — the document itself is kept even if
  /// this was its last linked trip.
  Future<ReceivingDocumentModel> removeTrip({
    required String documentId,
    required String tripId,
  }) async {
    try {
      final response = await _apiService.dio.delete('/api/receiving-documents/$documentId/trips/$tripId');
      return ReceivingDocumentModel.fromJson(
          (response.data as Map<String, dynamic>)['document'] as Map<String, dynamic>);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Paginated list of past uploads for the current org, newest first.
  Future<Map<String, dynamic>> list({int skip = 0, int limit = 50}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/receiving-documents',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
