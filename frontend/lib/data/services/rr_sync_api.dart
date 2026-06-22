import 'package:dio/dio.dart';
import 'package:fleet_management/data/services/api_service.dart';

// ─── Login result ─────────────────────────────────────────────────────────────

class RrLoginResult {
  final String token;
  final String rrUserId;
  const RrLoginResult({required this.token, required this.rrUserId});
}

// ─── API client ───────────────────────────────────────────────────────────────

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
  /// Body: {username, password} → returns {token, rr_user_id}
  Future<RrLoginResult> loginToRr(String username, String password) async {
    final resp = await _apiService.dio.post(
      '/api/rr/auth/login',
      data: {'username': username, 'password': password},
    );
    final data = resp.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) throw Exception('No token received');
    final rrUserId = data['rr_user_id'] as String? ?? '';
    return RrLoginResult(token: token, rrUserId: rrUserId);
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

  /// POST /api/rr/complete-trip/{trip_id}
  /// Body: {rr_token} — calls POST /create_trip on RR web, saves rr_trip_id + rr_parcel_id
  Future<Map<String, dynamic>> completeTripInRr(String tripId, String rrToken) async {
    final resp = await _apiService.dio.post(
      '/api/rr/complete-trip/$tripId',
      data: {'rr_token': rrToken},
    );
    return Map<String, dynamic>.from(resp.data);
  }
}
