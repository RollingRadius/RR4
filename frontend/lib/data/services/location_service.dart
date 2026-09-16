import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:fleet_management/data/models/driver_location.dart';
import 'package:fleet_management/data/services/tracking_api.dart';

/// GPS Location Service
/// Handles foreground location tracking with per-reading uploads, plus a
/// gyroscope-triggered "burst" fix so a longer, battery-friendly base
/// interval doesn't miss U-turns/sharp turns that happen entirely between
/// two scheduled readings. See docs/tracking/trail_accuracy_research.md.
class LocationService {
  final TrackingApi _trackingApi;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  Timer? _retryFlushTimer;

  // Failed sends only — this is not a batching queue, just a small retry
  // buffer so a transient network failure doesn't silently drop a point.
  final List<LocationCreate> _retryQueue = [];
  static const int _maxRetryQueueSize = 20;

  // Configuration
  static const Duration _positionInterval = Duration(seconds: 20); // base GPS update interval
  static const double _turnThresholdDegrees = 18.0; // accumulated heading change that triggers a burst fix
  static const Duration _turnTriggerCooldown = Duration(seconds: 8); // min gap between burst fixes

  // State
  bool _isTracking = false;
  Position? _lastPosition;
  double _accumulatedHeadingChangeDeg = 0;
  DateTime? _lastGyroSampleTime;
  DateTime? _lastTurnTriggerTime;
  bool _burstFixInFlight = false;

  LocationService(this._trackingApi);

  /// Check if tracking is currently active
  bool get isTracking => _isTracking;

  /// Get last known position
  Position? get lastPosition => _lastPosition;

  // ========================================================================
  // Permission Management
  // ========================================================================

  /// Check location permission status
  Future<PermissionStatus> checkPermission() async {
    return await Permission.location.status;
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get detailed permission status for UI
  Future<LocationPermissionStatus> getPermissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();

    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  /// Request appropriate permissions
  Future<bool> requestLocationPermission() async {
    // Check if service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException(
        'Location services are disabled. Please enable location services.',
      );
    }

    // Request permission
    final permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException(
        'Location permission denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(
        'Location permission permanently denied. Please enable it in settings.',
      );
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ========================================================================
  // Location Tracking
  // ========================================================================

  /// Start tracking location
  Future<void> startTracking() async {
    if (_isTracking) {
      debugPrint('📍 Location tracking already active');
      return;
    }

    // Check permission
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw LocationPermissionDeniedException('Location permission required');
    }

    // Check if tracking is enabled on backend
    // (This check should be done by the calling code)

    debugPrint('📍 Starting location tracking...');

    // On Android, a plain LocationSettings stream does NOT run a foreground
    // service — geolocator only starts one when given AndroidSettings with
    // foregroundNotificationConfig, which is required for GPS updates to
    // keep flowing once the app is backgrounded/screen-off (Android 10+).
    // The manifest already declares ACCESS_BACKGROUND_LOCATION /
    // FOREGROUND_SERVICE / FOREGROUND_SERVICE_LOCATION — this is what
    // actually puts them to use.
    final LocationSettings locationSettings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
            intervalDuration: _positionInterval,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'RR4 — Trip tracking active',
              notificationText: 'Sharing your location for your assigned trip',
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            timeLimit: _positionInterval,
          );

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onLocationUpdate,
      onError: _onLocationError,
      cancelOnError: false,
    );

    // Gyroscope runs continuously at near-zero battery cost, watching for a
    // heading change large enough to be a turn/U-turn. When one crosses the
    // threshold, it fires an immediate extra GPS fix rather than waiting for
    // the next scheduled reading — see docs/tracking/trail_accuracy_research.md
    // pass 4 for why this is needed at a 20s base interval.
    _accumulatedHeadingChangeDeg = 0;
    _lastGyroSampleTime = null;
    _gyroSubscription = gyroscopeEventStream().listen(
      _onGyroscopeEvent,
      onError: (_) {}, // gyroscope is a nice-to-have signal, never fatal
      cancelOnError: false,
    );

    // Periodically retry any sends that failed (network blip), independent
    // of the position stream itself.
    _retryFlushTimer = Timer.periodic(_positionInterval, (_) => _flushRetryQueue());

    _isTracking = true;
    debugPrint('✅ Location tracking started');
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }

    debugPrint('📍 Stopping location tracking...');

    // Cancel stream subscriptions
    await _positionStream?.cancel();
    _positionStream = null;
    await _gyroSubscription?.cancel();
    _gyroSubscription = null;

    // Cancel timers
    _retryFlushTimer?.cancel();
    _retryFlushTimer = null;

    // Best-effort flush of anything still waiting to be resent
    await _flushRetryQueue();

    _isTracking = false;
    debugPrint('✅ Location tracking stopped');
  }

  /// Handle a location update — from either the scheduled base-interval
  /// stream or a gyroscope-triggered burst fix (see _triggerBurstFix).
  void _onLocationUpdate(Position position) {
    _lastPosition = position;

    // A fresh authoritative fix just arrived — whatever heading change was
    // accumulating since the last one is now captured, so reset the trigger.
    _accumulatedHeadingChangeDeg = 0;

    // Get battery level (requires battery_plus package, simplified here)
    final batteryLevel = _getBatteryLevel();

    // Create location record
    final location = LocationCreate(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      batteryLevel: batteryLevel,
      isMockLocation: position.isMocked,
      // .toUtc() is essential here, not cosmetic — position.timestamp is
      // already UTC, but the DateTime.now() fallback is local. Without
      // this, a naive local-time string reaches the backend with no
      // offset marker, and asyncpg silently assumes naive datetimes are
      // already UTC — corrupting every staleness/age calculation by the
      // device's UTC offset.
      timestamp: position.timestamp.toUtc(),
    );

    debugPrint('📍 Location captured: ${position.latitude}, ${position.longitude}');
    _sendLocation(location);
  }

  /// Handle location error
  void _onLocationError(dynamic error) {
    debugPrint('❌ Location error: $error');
  }

  /// Watches the gyroscope for a sustained heading change large enough to be
  /// a turn/U-turn, and fires an immediate extra GPS fix when one is
  /// detected — this is what lets the base interval stay long (20s) without
  /// missing maneuvers that happen entirely between two scheduled readings.
  void _onGyroscopeEvent(GyroscopeEvent event) {
    final now = DateTime.now();
    final lastSample = _lastGyroSampleTime;
    _lastGyroSampleTime = now;
    if (lastSample == null) return; // first sample, no elapsed time to integrate over

    final dtSeconds = now.difference(lastSample).inMicroseconds / 1e6;
    if (dtSeconds <= 0 || dtSeconds > 2) return; // ignore stale/backgrounded gaps

    // event.z is yaw rate (rad/s) around the phone's vertical axis for a
    // typical flat dashboard/cupholder mount — integrate to accumulated
    // heading change in degrees since the last confirmed GPS fix.
    _accumulatedHeadingChangeDeg += event.z.abs() * dtSeconds * (180 / math.pi);

    if (_accumulatedHeadingChangeDeg < _turnThresholdDegrees) return;

    final lastTrigger = _lastTurnTriggerTime;
    if (lastTrigger != null && now.difference(lastTrigger) < _turnTriggerCooldown) {
      return; // still in cooldown — don't spam through one long curve
    }

    _triggerBurstFix();
  }

  /// Fires one extra GPS fix outside the normal scheduled interval, in
  /// response to a detected turn.
  Future<void> _triggerBurstFix() async {
    if (_burstFixInFlight || !_isTracking) return;
    _burstFixInFlight = true;
    _lastTurnTriggerTime = DateTime.now();
    debugPrint('🔄 Turn detected — firing burst GPS fix');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _onLocationUpdate(position);
    } catch (e) {
      debugPrint('❌ Burst fix failed: $e');
    } finally {
      _burstFixInFlight = false;
    }
  }

  /// Send a single location immediately. On failure, it's kept in a small
  /// retry buffer (not a batching queue — just resilience against a
  /// transient network blip) rather than being silently dropped.
  Future<void> _sendLocation(LocationCreate location) async {
    try {
      await _trackingApi.createLocation(location);
      debugPrint('✅ Location sent: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('❌ Failed to send location, queued for retry: $e');
      _retryQueue.add(location);
      if (_retryQueue.length > _maxRetryQueueSize) {
        _retryQueue.removeAt(0); // drop oldest, keep the most recent history
      }
    }
  }

  /// Retries any locations that failed to send. Stops at the first failure
  /// to preserve chronological order rather than reshuffling the queue.
  Future<void> _flushRetryQueue() async {
    while (_retryQueue.isNotEmpty) {
      final next = _retryQueue.first;
      try {
        await _trackingApi.createLocation(next);
        _retryQueue.removeAt(0);
      } catch (e) {
        debugPrint('❌ Retry flush still failing, will try again later: $e');
        break;
      }
    }
  }

  /// Get current position once
  Future<Position> getCurrentPosition() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw LocationPermissionDeniedException('Location permission required');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Get battery level (simplified - requires battery_plus package)
  int? _getBatteryLevel() {
    // TODO: Implement battery level reading
    // For now, return null
    return null;
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}

// ============================================================================
// Enums & Exceptions
// ============================================================================

/// Location permission status
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
  serviceDisabled,
}

extension LocationPermissionStatusExtension on LocationPermissionStatus {
  String get displayName {
    switch (this) {
      case LocationPermissionStatus.denied:
        return 'Permission Denied';
      case LocationPermissionStatus.deniedForever:
        return 'Permission Permanently Denied';
      case LocationPermissionStatus.whileInUse:
        return 'While In Use';
      case LocationPermissionStatus.always:
        return 'Always';
      case LocationPermissionStatus.serviceDisabled:
        return 'Location Service Disabled';
    }
  }

  bool get isGranted =>
      this == LocationPermissionStatus.whileInUse ||
      this == LocationPermissionStatus.always;
}

/// Location permission denied exception
class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);

  @override
  String toString() => message;
}

/// Location service disabled exception
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);

  @override
  String toString() => message;
}
