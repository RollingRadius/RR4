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

  // ─── Quick-add: Vehicle / Company / User directly on RR ──────────────────────

  /// GET /api/rr/users/search?q=&rr_token= — typeahead by phone prefix or name.
  /// [driversOnly] restricts results to driver-role users (plus untagged
  /// legacy users) — only the trip Driver picker should pass true; other
  /// callers (vehicle owner / company contact / hire-person search) must
  /// leave it false so non-driver users aren't excluded.
  Future<List<Map<String, dynamic>>> searchRrUsers(
    String q,
    String rrToken, {
    bool driversOnly = false,
  }) async {
    if (q.isEmpty) return [];
    final resp = await _apiService.dio.get(
      '/api/rr/users/search',
      queryParameters: {'q': q, 'rr_token': rrToken, 'drivers_only': driversOnly},
    );
    final items = (resp.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// GET /api/rr/companies/search?q=&rr_token= — typeahead by company name
  Future<List<Map<String, dynamic>>> searchRrCompanies(String q, String rrToken) async {
    if (q.isEmpty) return [];
    final resp = await _apiService.dio.get(
      '/api/rr/companies/search',
      queryParameters: {'q': q, 'rr_token': rrToken},
    );
    final items = (resp.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// GET /api/rr/vehicle-engine-models/search?q=&rr_token= — typeahead by engine model name
  Future<List<Map<String, dynamic>>> searchVehicleEngineModels(String q, String rrToken) async {
    if (q.isEmpty) return [];
    final resp = await _apiService.dio.get(
      '/api/rr/vehicle-engine-models/search',
      queryParameters: {'q': q, 'rr_token': rrToken},
    );
    final items = (resp.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// POST /api/rr/vehicles — creates a new vehicle directly on RR
  Future<Map<String, dynamic>> createRrVehicle({
    required String rrToken,
    required String engineModelId,
    required String rcNumber,
    required String ownerUserId,
    String? companyId,
  }) async {
    final resp = await _apiService.dio.post(
      '/api/rr/vehicles',
      data: {
        'rr_token': rrToken,
        'engine_model_id': engineModelId,
        'rc_number': rcNumber,
        'owner_user_id': ownerUserId,
        'company_id': companyId,
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// POST /api/rr/vehicles/assign-driver — attaches a driver to a vehicle's RR
  /// crew. RR's own booking confirmation reads the driver off the vehicle's
  /// crew field, not off any driver id passed alongside a trip — required
  /// before RR will let a driverless vehicle be booked.
  Future<Map<String, dynamic>> assignVehicleDriver({
    required String rrToken,
    required String vehicleId,
    required String driverUserId,
  }) async {
    final resp = await _apiService.dio.post(
      '/api/rr/vehicles/assign-driver',
      data: {
        'rr_token': rrToken,
        'vehicle_id': vehicleId,
        'driver_user_id': driverUserId,
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// POST /api/rr/companies — creates a new company (vehicle provider) directly on RR
  Future<Map<String, dynamic>> createRrCompany({
    required String rrToken,
    required String name,
    required String cityId,
    required String businessType,
    String? ownerUserId,
    String? newOwnerPhone,
  }) async {
    final resp = await _apiService.dio.post(
      '/api/rr/companies',
      data: {
        'rr_token': rrToken,
        'name': name,
        'city_id': cityId,
        'business_type': businessType,
        'owner_user_id': ownerUserId,
        'new_owner_phone': newOwnerPhone,
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// POST /api/rr/users — creates a new user (driver) directly on RR
  Future<Map<String, dynamic>> createRrUser({
    required String rrToken,
    required String name,
    required String phone,
  }) async {
    final resp = await _apiService.dio.post(
      '/api/rr/users',
      data: {'rr_token': rrToken, 'name': name, 'phone': phone},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  // ─── Vehicle hire requests ────────────────────────────────────────────────────

  /// GET /api/rr/vehicle-hire-requests — pending hire requests for vehicles
  /// your company owns
  Future<List<Map<String, dynamic>>> getVehicleHireRequests(String rrToken) async {
    final resp = await _apiService.dio.get(
      '/api/rr/vehicle-hire-requests',
      queryParameters: {'rr_token': rrToken},
    );
    final items = (resp.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// POST /api/rr/vehicle-hire-requests/{id}/review — approve or reject
  Future<void> reviewVehicleHireRequest({
    required String marketVehicleId,
    required String rrToken,
    required String status, // "Approved" | "Rejected"
    String? approvedStartDate,
    String? approvedEndDate,
  }) async {
    await _apiService.dio.post(
      '/api/rr/vehicle-hire-requests/$marketVehicleId/review',
      data: {
        'rr_token': rrToken,
        'status': status,
        if (approvedStartDate != null) 'approved_start_date': approvedStartDate,
        if (approvedEndDate != null) 'approved_end_date': approvedEndDate,
      },
    );
  }

  /// POST /api/rr/vehicle-hire-requests — request to hire a vehicle you don't own
  Future<Map<String, dynamic>> createVehicleHireRequest({
    required String rrToken,
    required String vehicleId,
    String? ownerUserId,
    String? ownerCompanyId,
    String? hirerUserId,
    String? hirerCompanyId,
    String? requestedStartDate,
    String? requestedEndDate,
  }) async {
    final resp = await _apiService.dio.post(
      '/api/rr/vehicle-hire-requests',
      data: {
        'rr_token': rrToken,
        'vehicle_id': vehicleId,
        'owner_user_id': ownerUserId,
        'owner_company_id': ownerCompanyId,
        'hirer_user_id': hirerUserId,
        'hirer_company_id': hirerCompanyId,
        'requested_start_date': requestedStartDate,
        'requested_end_date': requestedEndDate,
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// GET /api/rr/user-vehicles — vehicles personally owned by an RR user
  Future<List<Map<String, dynamic>>> getUserVehicles(String userId, String rrToken) async {
    final resp = await _apiService.dio.get(
      '/api/rr/user-vehicles',
      queryParameters: {'user_id': userId, 'rr_token': rrToken},
    );
    final vehicles = (resp.data as Map<String, dynamic>)['vehicles'] as List? ?? [];
    return vehicles.cast<Map<String, dynamic>>();
  }

  /// GET /api/rr/company-vehicles — vehicles owned by an RR company
  Future<List<Map<String, dynamic>>> getCompanyVehicles(String companyId, String rrToken) async {
    final resp = await _apiService.dio.get(
      '/api/rr/company-vehicles',
      queryParameters: {'company_id': companyId, 'rr_token': rrToken},
    );
    final vehicles = (resp.data as Map<String, dynamic>)['vehicles'] as List? ?? [];
    return vehicles.cast<Map<String, dynamic>>();
  }
}
