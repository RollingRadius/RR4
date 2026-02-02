import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/tracking_api.dart';
import 'package:fleet_management/data/models/driver_location.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';

/// Live Tracking State
class LiveTrackingState {
  final List<LiveLocation> locations;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefresh;
  final bool autoRefresh;
  final LiveLocation? selectedDriver;

  LiveTrackingState({
    this.locations = const [],
    this.isLoading = false,
    this.error,
    this.lastRefresh,
    this.autoRefresh = true,
    this.selectedDriver,
  });

  LiveTrackingState copyWith({
    List<LiveLocation>? locations,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
    bool? autoRefresh,
    LiveLocation? selectedDriver,
  }) {
    return LiveTrackingState(
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      selectedDriver: selectedDriver,
    );
  }

  /// Get active drivers (updated in last 5 minutes)
  List<LiveLocation> get activeDrivers {
    return locations
        .where((loc) => loc.status == LocationStatus.active)
        .toList();
  }

  /// Get idle drivers
  List<LiveLocation> get idleDrivers {
    return locations
        .where((loc) => loc.status == LocationStatus.idle)
        .toList();
  }

  /// Get offline drivers (no update in 5+ minutes)
  List<LiveLocation> get offlineDrivers {
    return locations
        .where((loc) => loc.status == LocationStatus.offline)
        .toList();
  }

  /// Get total count
  int get totalDrivers => locations.length;

  /// Get counts by status
  Map<LocationStatus, int> get statusCounts {
    final counts = <LocationStatus, int>{
      LocationStatus.active: 0,
      LocationStatus.idle: 0,
      LocationStatus.offline: 0,
    };

    for (final location in locations) {
      counts[location.status] = (counts[location.status] ?? 0) + 1;
    }

    return counts;
  }
}

/// Live Tracking Notifier
class LiveTrackingNotifier extends StateNotifier<LiveTrackingState> {
  final TrackingApi _trackingApi;
  Timer? _refreshTimer;

  static const Duration _refreshInterval = Duration(seconds: 30);

  LiveTrackingNotifier(this._trackingApi) : super(LiveTrackingState());

  /// Start auto-refresh
  void startAutoRefresh() {
    if (state.autoRefresh) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(_refreshInterval, (_) {
        fetchLiveLocations();
      });
    }
  }

  /// Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Toggle auto-refresh
  void toggleAutoRefresh() {
    final newValue = !state.autoRefresh;
    state = state.copyWith(autoRefresh: newValue);

    if (newValue) {
      startAutoRefresh();
      fetchLiveLocations(); // Immediate fetch
    } else {
      stopAutoRefresh();
    }
  }

  /// Fetch live locations for all drivers
  Future<void> fetchLiveLocations({List<String>? driverIds}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final locations = await _trackingApi.getLiveLocations(
        driverIds: driverIds,
      );

      state = state.copyWith(
        locations: locations,
        isLoading: false,
        lastRefresh: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch location for specific driver
  Future<void> fetchDriverLocation(String driverId) async {
    try {
      final location = await _trackingApi.getDriverLocation(driverId);

      // Update or add to locations list
      final updatedLocations = List<LiveLocation>.from(state.locations);
      final index = updatedLocations.indexWhere(
        (loc) => loc.driverId == driverId,
      );

      if (index >= 0) {
        updatedLocations[index] = location;
      } else {
        updatedLocations.add(location);
      }

      state = state.copyWith(
        locations: updatedLocations,
        lastRefresh: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Select a driver on the map
  void selectDriver(String? driverId) {
    if (driverId == null) {
      state = state.copyWith(selectedDriver: null);
      return;
    }

    final driver = state.locations.firstWhere(
      (loc) => loc.driverId == driverId,
      orElse: () => state.locations.first,
    );

    state = state.copyWith(selectedDriver: driver);
  }

  /// Clear selected driver
  void clearSelection() {
    state = state.copyWith(selectedDriver: null);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Live Tracking Provider
final liveTrackingProvider =
    StateNotifierProvider<LiveTrackingNotifier, LiveTrackingState>(
  (ref) {
    final trackingApi = ref.watch(trackingApiProvider);
    final notifier = LiveTrackingNotifier(trackingApi);

    // Start auto-refresh when provider is created
    notifier.startAutoRefresh();

    return notifier;
  },
);
