import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/data/models/driver_location.dart';
import 'package:fleet_management/data/models/geofence_event.dart';
import 'package:fleet_management/data/models/route_optimization.dart';

/// GPS Tracking API Service
/// Handles all tracking-related API calls
class TrackingApi {
  final ApiService _apiService;

  TrackingApi(this._apiService);

  // ========================================================================
  // Location Tracking
  // ========================================================================

  /// Submit a single location record
  Future<DriverLocation> createLocation(LocationCreate location) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/tracking/locations',
        data: location.toJson(),
      );
      return DriverLocation.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Submit batch of location records (more efficient)
  Future<Map<String, dynamic>> createLocationBatch(
    List<LocationCreate> locations,
  ) async {
    try {
      final batch = LocationBatchCreate(locations: locations);
      final response = await _apiService.dio.post(
        '/api/v1/tracking/locations/batch',
        data: batch.toJson(),
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get live locations for all drivers
  Future<List<LiveLocation>> getLiveLocations({
    List<String>? driverIds,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/locations/live',
        queryParameters: {
          if (driverIds != null && driverIds.isNotEmpty)
            'driver_ids': driverIds,
        },
      );

      final List<dynamic> data = response.data;
      return data.map((json) => LiveLocation.fromJson(json)).toList();
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get current location for a specific driver
  Future<LiveLocation> getDriverLocation(String driverId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/drivers/$driverId/location',
      );
      return LiveLocation.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get location history for a driver
  Future<LocationListResponse> getDriverHistory({
    required String driverId,
    required DateTime startTime,
    required DateTime endTime,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/drivers/$driverId/history',
        queryParameters: {
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'page': page,
          'page_size': pageSize,
        },
      );
      return LocationListResponse.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  // ========================================================================
  // Geofencing
  // ========================================================================

  /// Report a geofence event (enter/exit)
  Future<GeofenceEvent> createGeofenceEvent(
    GeofenceEventCreate event,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/tracking/geofences/events',
        data: event.toJson(),
      );
      return GeofenceEvent.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get geofence event history
  Future<GeofenceEventListResponse> getGeofenceEvents({
    String? driverId,
    String? zoneId,
    DateTime? startTime,
    DateTime? endTime,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/geofences/events',
        queryParameters: {
          if (driverId != null) 'driver_id': driverId,
          if (zoneId != null) 'zone_id': zoneId,
          if (startTime != null) 'start_time': startTime.toIso8601String(),
          if (endTime != null) 'end_time': endTime.toIso8601String(),
          'page': page,
          'page_size': pageSize,
        },
      );
      return GeofenceEventListResponse.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  // ========================================================================
  // Route Optimization
  // ========================================================================

  /// Optimize route using OSRM
  Future<RouteOptimizeResponse> optimizeRoute(
    List<Waypoint> waypoints,
  ) async {
    try {
      final request = RouteOptimizeRequest(waypoints: waypoints);
      final response = await _apiService.dio.post(
        '/api/v1/tracking/routes/optimize',
        data: request.toJson(),
      );
      return RouteOptimizeResponse.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get list of saved routes
  Future<RouteListResponse> getRoutes({
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/routes',
        queryParameters: {
          if (statusFilter != null) 'status_filter': statusFilter,
          'page': page,
          'page_size': pageSize,
        },
      );
      return RouteListResponse.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Create a saved route
  Future<RouteOptimization> createRoute(RouteCreate route) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/tracking/routes',
        data: route.toJson(),
      );
      return RouteOptimization.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get route details
  Future<RouteOptimization> getRoute(String routeId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/routes/$routeId',
      );
      return RouteOptimization.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update a route
  Future<RouteOptimization> updateRoute(
    String routeId,
    RouteUpdate update,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '/api/v1/tracking/routes/$routeId',
        data: update.toJson(),
      );
      return RouteOptimization.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete a route
  Future<void> deleteRoute(String routeId) async {
    try {
      await _apiService.dio.delete(
        '/api/v1/tracking/routes/$routeId',
      );
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  // ========================================================================
  // Admin Controls
  // ========================================================================

  /// Enable or disable tracking for a driver
  Future<Map<String, dynamic>> updateDriverTracking(
    String driverId,
    bool enabled,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '/api/v1/tracking/drivers/$driverId/tracking',
        data: {'tracking_enabled': enabled},
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get tracking status for a driver
  Future<Map<String, dynamic>> getDriverTrackingStatus(
    String driverId,
  ) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/drivers/$driverId/tracking',
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  // ========================================================================
  // Analytics
  // ========================================================================

  /// Get trip analytics summary
  Future<Map<String, dynamic>> getTripAnalytics({
    required String driverId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/tracking/analytics/summary',
        queryParameters: {
          'driver_id': driverId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
        },
      );
      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
