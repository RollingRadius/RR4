import 'package:fleet_management/data/services/api_service.dart';

/// RR Sync API — proxy calls to /api/v1/rr/*
class RrSyncApi {
  final ApiService _apiService;
  RrSyncApi(this._apiService);

  /// GET /api/v1/rr/sync/ready
  /// Returns {ready: [...], missing_data: [...], ready_count: int}
  Future<Map<String, dynamic>> getReadyTrips() async {
    final resp = await _apiService.dio.get('/api/rr/sync/ready');
    return Map<String, dynamic>.from(resp.data);
  }

  /// POST /api/rr/sync/bulk
  /// Body: {trip_ids: [...]}
  /// Returns {queued: [...], skipped: [...], message: str}
  Future<Map<String, dynamic>> triggerBulkSync(List<String> tripIds) async {
    final resp = await _apiService.dio.post(
      '/api/rr/sync/bulk',
      data: {'trip_ids': tripIds},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// GET /api/rr/sync/status/{trip_id}
  Future<Map<String, dynamic>> getSyncStatus(String tripId) async {
    final resp = await _apiService.dio.get('/api/rr/sync/status/$tripId');
    return Map<String, dynamic>.from(resp.data);
  }
}
