import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:fleet_management/data/models/driver_location.dart';
import 'package:fleet_management/data/services/tracking_api.dart';

/// GPS Location Service
/// Handles foreground location tracking with batch uploads
class LocationService {
  final TrackingApi _trackingApi;

  StreamSubscription<Position>? _positionStream;
  final List<LocationCreate> _batchQueue = [];
  Timer? _batchTimer;
  Timer? _positionTimer;

  // Configuration
  static const int _maxBatchSize = 5; // Send batch after 5 locations
  static const Duration _batchInterval = Duration(seconds: 60); // Or after 60s
  static const Duration _positionInterval = Duration(seconds: 15); // GPS update interval

  // State
  bool _isTracking = false;
  Position? _lastPosition;

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

    // Configure location settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeLimit: Duration(seconds: 15), // Or every 15 seconds
    );

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onLocationUpdate,
      onError: _onLocationError,
      cancelOnError: false,
    );

    // Start batch upload timer
    _batchTimer = Timer.periodic(_batchInterval, (_) => _sendBatch());

    _isTracking = true;
    debugPrint('✅ Location tracking started');
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }

    debugPrint('📍 Stopping location tracking...');

    // Cancel stream subscription
    await _positionStream?.cancel();
    _positionStream = null;

    // Cancel timers
    _batchTimer?.cancel();
    _batchTimer = null;
    _positionTimer?.cancel();
    _positionTimer = null;

    // Send remaining locations in queue
    await _sendBatch();

    _isTracking = false;
    debugPrint('✅ Location tracking stopped');
  }

  /// Handle location update
  void _onLocationUpdate(Position position) {
    _lastPosition = position;

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
      timestamp: position.timestamp ?? DateTime.now(),
    );

    // Add to batch queue
    _batchQueue.add(location);
    debugPrint('📍 Location queued: ${position.latitude}, ${position.longitude} (Queue: ${_batchQueue.length})');

    // Send batch if queue reaches max size
    if (_batchQueue.length >= _maxBatchSize) {
      debugPrint('📤 Batch size reached, sending locations...');
      _sendBatch();
    }
  }

  /// Handle location error
  void _onLocationError(dynamic error) {
    debugPrint('❌ Location error: $error');
  }

  /// Send batch of locations to backend
  Future<void> _sendBatch() async {
    if (_batchQueue.isEmpty) {
      return;
    }

    // Copy queue and clear
    final locationsToSend = List<LocationCreate>.from(_batchQueue);
    _batchQueue.clear();

    debugPrint('📤 Sending batch of ${locationsToSend.length} locations...');

    try {
      final result = await _trackingApi.createLocationBatch(locationsToSend);
      debugPrint('✅ Batch sent successfully: ${result['count']} locations');

      if (result['skipped'] != null && result['skipped'] > 0) {
        debugPrint('⚠️ ${result['skipped']} locations skipped (low accuracy)');
      }
    } catch (e) {
      debugPrint('❌ Failed to send batch: $e');

      // Re-add to queue on failure (keep last 20 to avoid memory issues)
      _batchQueue.insertAll(0, locationsToSend);
      if (_batchQueue.length > 20) {
        _batchQueue.removeRange(20, _batchQueue.length);
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
