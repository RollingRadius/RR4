import 'package:dio/dio.dart';
import 'package:fleet_management/data/services/api_service.dart';

/// RR Sync API — proxy calls to /api/rr/*
class RrSyncApi {
  final ApiService _apiService;
  RrSyncApi(this._apiService);

  Dio get dio => _apiService.dio;

  /// GET /api/rr/sync/ready
  /// Returns {ready: [...], missing_data: [...], ready_count: int}
  Future<Map<String, dynamic>> getReadyTrips() async {
    final resp = await _apiService.dio.get('/api/rr/sync/ready');
    return Map<String, dynamic>.from(resp.data);
  }

  /// POST /api/rr/auth/login
  /// Body: {username, password} → returns {token}
  Future<String> loginToRr(String username, String password) async {
    final resp = await _apiService.dio.post(
      '/api/rr/auth/login',
      data: {'username': username, 'password': password},
    );
    final token = (resp.data as Map<String, dynamic>)['token'] as String?;
    if (token == null || token.isEmpty) throw Exception('No token received');
    return token;
  }

  /// POST /api/rr/sync/trip/{trip_id}
  /// Body: {rr_token} — syncs a single trip using the LP's own RR token
  Future<Map<String, dynamic>> triggerTripSync(String tripId, String rrToken) async {
    final resp = await _apiService.dio.post(
      '/api/rr/sync/trip/$tripId',
      data: {'rr_token': rrToken},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// GET /api/rr/sync/status/{trip_id}
  Future<Map<String, dynamic>> getSyncStatus(String tripId) async {
    final resp = await _apiService.dio.get('/api/rr/sync/status/$tripId');
    return Map<String, dynamic>.from(resp.data);
  }
}
