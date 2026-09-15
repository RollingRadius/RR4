import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/data/services/tracking_api.dart';
import 'package:fleet_management/data/services/location_service.dart';
import 'package:fleet_management/data/services/background_tracking_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';

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

  /// Self-lookup version of the above — no driver_id needed, works for the
  /// current user's own driver profile. Silently no-ops if the account has
  /// no linked driver (e.g. not a driver-role user), so callers can call
  /// this unconditionally without checking role first.
  Future<void> refreshMyTrackingEnabled() async {
    try {
      final response = await _trackingApi.getMyTrackingStatus();
      state = state.copyWith(trackingEnabled: response['tracking_enabled'] as bool);
    } catch (e) {
      // No driver profile, or a transient error — leave trackingEnabled as-is
      // (never surfaced to the user), but log it so a silent tracking
      // failure is traceable in device logs instead of leaving no trace.
      debugPrint('⚠️ refreshMyTrackingEnabled failed: $e');
    }
  }

  /// One-time flow: called once permission has just been granted. Flips the
  /// backend flag on for the current user's own driver record (self-service,
  /// no admin action needed — see tracking.py's PUT .../tracking) and
  /// updates local state to match. Silently no-ops if there's no driver
  /// profile for this account.
  Future<void> selfEnableTracking() async {
    try {
      final status = await _trackingApi.getMyTrackingStatus();
      final driverId = status['driver_id'] as String;
      if (status['tracking_enabled'] == true) {
        state = state.copyWith(trackingEnabled: true);
        return;
      }
      await _trackingApi.updateDriverTracking(driverId, true);
      state = state.copyWith(trackingEnabled: true);
    } catch (e) {
      // No driver profile, or a transient error — leave trackingEnabled as-is;
      // the app never blocks or nags the user over this, but log it so a
      // silent self-enable failure is traceable in device logs.
      debugPrint('⚠️ selfEnableTracking failed: $e');
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

/// Starts tracking if the current driver has an active (ongoing/pending)
/// trip assigned, stops it otherwise. Shared by driver_dashboard_screen.dart
/// (initial load + 30s poll) and main.dart (app-resume lifecycle hook), so
/// both entry points stay in sync without duplicating the logic. Safe to
/// call for any role — no-ops harmlessly if there are simply no trips.
Future<void> syncDriverTrackingToActiveTrip(WidgetRef ref) async {
  // Belt-and-suspenders: every current call site already gates on
  // user?.isDriver before calling this, but tripProvider's "ongoing trip"
  // check below has no idea whose trips they are — a non-driver role with
  // its own ongoing trips (e.g. logistic_partner) would otherwise pass this
  // check too and start submitting location data the backend rejects as
  // "Only drivers can submit location data."
  final user = ref.read(authProvider).user;
  if (user?.isDriver != true) {
    await ref.read(locationTrackingProvider.notifier).stopTracking();
    return;
  }

  final trips = ref.read(tripProvider).trips;
  final hasActiveTrip = trips.any((t) =>
      (t.isOngoing || t.isPending) && !t.isStage5Complete && !t.driverTrackingStopped);
  final notifier = ref.read(locationTrackingProvider.notifier);
  await notifier.refreshMyTrackingEnabled();
  // Also refresh the live OS permission status here (not just at initial
  // load) — this is the only periodic recheck point, so it's what keeps the
  // driver dashboard's permission toggle accurate if the driver grants/denies
  // permission from the phone's own Settings app and comes back.
  await notifier.checkPermission();
  final permissionStatus = ref.read(locationTrackingProvider).permissionStatus;
  // Best-effort self-report to the backend — it otherwise has zero
  // visibility into OS permission state, and uses this to decide whether to
  // send a "turn on location" reminder push. Never blocks the tracking
  // start/stop decision below on failure.
  if (permissionStatus != null) {
    try {
      await ref.read(trackingApiProvider).reportMyPermissionStatus(permissionStatus.name);
    } catch (_) {}
  }
  final trackingEnabled = ref.read(locationTrackingProvider).trackingEnabled;
  // A driver who has granted "Always Allow" (background) location keeps
  // being tracked continuously, trip or no trip, so LP/RR-ops can locate
  // them anytime via the Track sidebar search. Drivers on "While Using the
  // App" keep the original trip-scoped behavior — the OS itself blocks
  // background GPS for that tier regardless of what this code does.
  final alwaysAllowed = permissionStatus == LocationPermissionStatus.always;
  // trackingEnabled can flip false mid-session (an admin disabling it via
  // PUT /drivers/{id}/tracking while this driver is already tracking) —
  // startTracking()'s own trackingEnabled guard only runs on a fresh start,
  // it never re-checks once isTracking is already true, so this explicit
  // stop is what actually honors an admin's disable while a trip is active.
  if (trackingEnabled && alwaysAllowed) {
    // Always-tier drivers get the durable background service instead of the
    // UI-isolate LocationService, so tracking survives the app being closed
    // and the driver logging out — stop the UI-isolate path to avoid
    // double-tracking/duplicate uploads for the same driver.
    await notifier.stopTracking();
    await _ensureBackgroundTrackingStarted(user!.userId);
  } else if (trackingEnabled && hasActiveTrip) {
    // Defensive: in case permission was ever downgraded from "always" while
    // the background service was running for this driver.
    await BackgroundTrackingService.stop();
    await notifier.startTracking();
  } else {
    await notifier.stopTracking();
    await BackgroundTrackingService.stop();
  }
}

/// Starts the durable background tracking service for [userId] if it isn't
/// already running for them — persisting a fresh copy of the current
/// refresh token as the service's own auth-session-independent credential
/// on first use. Safe to call repeatedly (idempotent).
Future<void> _ensureBackgroundTrackingStarted(String userId) async {
  final persistedDriverId = await BackgroundTrackingService.currentDriverId();
  if (persistedDriverId == userId) {
    await BackgroundTrackingService.start();
    return;
  }
  const storage = FlutterSecureStorage();
  final refreshToken = await storage.read(key: AppConfig.refreshTokenKey);
  if (refreshToken != null && refreshToken.isNotEmpty) {
    await BackgroundTrackingService.startForDriver(
      driverId: userId,
      refreshToken: refreshToken,
    );
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
