import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/tracking_api.dart';
import 'package:fleet_management/data/services/location_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Tracking API Provider
final trackingApiProvider = Provider<TrackingApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TrackingApi(apiService);
});

/// Location Service Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  final trackingApi = ref.watch(trackingApiProvider);
  return LocationService(trackingApi);
});

/// Location Tracking State
class LocationTrackingState {
  final bool isTracking;
  final bool isLoading;
  final String? error;
  final LocationPermissionStatus? permissionStatus;
  final int queuedLocations;
  final DateTime? lastUpdate;
  final bool trackingEnabled; // Backend tracking enabled

  LocationTrackingState({
    this.isTracking = false,
    this.isLoading = false,
    this.error,
    this.permissionStatus,
    this.queuedLocations = 0,
    this.lastUpdate,
    this.trackingEnabled = false,
  });

  LocationTrackingState copyWith({
    bool? isTracking,
    bool? isLoading,
    String? error,
    LocationPermissionStatus? permissionStatus,
    int? queuedLocations,
    DateTime? lastUpdate,
    bool? trackingEnabled,
  }) {
    return LocationTrackingState(
      isTracking: isTracking ?? this.isTracking,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      queuedLocations: queuedLocations ?? this.queuedLocations,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
    );
  }
}

/// Location Tracking Notifier
class LocationTrackingNotifier extends StateNotifier<LocationTrackingState> {
  final LocationService _locationService;
  final TrackingApi _trackingApi;

  LocationTrackingNotifier(this._locationService, this._trackingApi)
      : super(LocationTrackingState());

  /// Check permission status
  Future<void> checkPermission() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final status = await _locationService.getPermissionStatus();
      state = state.copyWith(
        permissionStatus: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final granted = await _locationService.requestLocationPermission();
      final status = await _locationService.getPermissionStatus();

      state = state.copyWith(
        permissionStatus: status,
        isLoading: false,
      );

      return granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check if tracking is enabled on backend
  Future<void> checkTrackingEnabled(String driverId) async {
    try {
      final response = await _trackingApi.getDriverTrackingStatus(driverId);
      state = state.copyWith(
        trackingEnabled: response['tracking_enabled'] as bool,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Start location tracking
  Future<void> startTracking() async {
    if (state.isTracking) {
      return;
    }

    if (!state.trackingEnabled) {
      state = state.copyWith(
        error: 'Tracking not enabled by administrator',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _locationService.startTracking();

      state = state.copyWith(
        isTracking: true,
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isTracking: false,
        error: e.toString(),
      );
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!state.isTracking) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _locationService.stopTracking();

      state = state.copyWith(
        isTracking: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle tracking
  Future<void> toggleTracking() async {
    if (state.isTracking) {
      await stopTracking();
    } else {
      await startTracking();
    }
  }

  /// Update last update timestamp
  void updateLastUpdate() {
    state = state.copyWith(lastUpdate: DateTime.now());
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Location Tracking Provider
final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>(
  (ref) {
    final locationService = ref.watch(locationServiceProvider);
    final trackingApi = ref.watch(trackingApiProvider);
    return LocationTrackingNotifier(locationService, trackingApi);
  },
);
