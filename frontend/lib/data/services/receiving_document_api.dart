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

  /// Search trips by RR4's own trip number OR the RR-web-assigned number
  /// (once synced), AND/OR by Stage-4 bilty number — server-side, so it
  /// isn't limited to whatever page of trips the dashboard happens to have
  /// already loaded. Mirrors the main dashboard's two independent search
  /// boxes: pass [query] and/or [biltyQuery]; when both are given they're
  /// ANDed together, same as matchesTripSearch + matchesBiltySearch there.
  Future<List<TripSearchResult>> searchTrips({String? query, String? biltyQuery}) async {
    final q = query?.trim() ?? '';
    final bilty = biltyQuery?.trim() ?? '';
    if (q.isEmpty && bilty.isEmpty) return const [];
    try {
      final response = await _apiService.dio.get(
        '/api/receiving-documents/search-trips',
        queryParameters: {
          if (q.isNotEmpty) 'q': q,
          if (bilty.isNotEmpty) 'bilty': bilty,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['trips'] as List<dynamic>? ?? [])
          .map((e) => TripSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
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
  /// [q] matches a linked trip's RR4/RR-web trip number; [bilty] matches
  /// only its bilty number — both may be given together (AND), mirroring
  /// the two independent search boxes elsewhere in the app.
  Future<Map<String, dynamic>> list({int skip = 0, int limit = 50, String? q, String? bilty}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/receiving-documents',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (bilty != null && bilty.trim().isNotEmpty) 'bilty': bilty.trim(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
