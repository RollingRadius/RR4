import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/tracking_api.dart';
import 'package:fleet_management/data/models/geofence_event.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';

/// Geofence State
class GeofenceState {
  final List<GeofenceEvent> events;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetch;
  final int currentPage;
  final int totalEvents;
  final bool hasMore;

  GeofenceState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.lastFetch,
    this.currentPage = 1,
    this.totalEvents = 0,
    this.hasMore = false,
  });

  GeofenceState copyWith({
    List<GeofenceEvent>? events,
    bool? isLoading,
    String? error,
    DateTime? lastFetch,
    int? currentPage,
    int? totalEvents,
    bool? hasMore,
  }) {
    return GeofenceState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetch: lastFetch ?? this.lastFetch,
      currentPage: currentPage ?? this.currentPage,
      totalEvents: totalEvents ?? this.totalEvents,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Get enter events
  List<GeofenceEvent> get enterEvents {
    return events.where((e) => e.isEnter).toList();
  }

  /// Get exit events
  List<GeofenceEvent> get exitEvents {
    return events.where((e) => e.isExit).toList();
  }

  /// Group events by zone
  Map<String, List<GeofenceEvent>> get eventsByZone {
    final grouped = <String, List<GeofenceEvent>>{};

    for (final event in events) {
      final zoneName = event.zoneName;
      if (!grouped.containsKey(zoneName)) {
        grouped[zoneName] = [];
      }
      grouped[zoneName]!.add(event);
    }

    return grouped;
  }

  /// Group events by driver
  Map<String, List<GeofenceEvent>> get eventsByDriver {
    final grouped = <String, List<GeofenceEvent>>{};

    for (final event in events) {
      final driverName = event.driverName;
      if (!grouped.containsKey(driverName)) {
        grouped[driverName] = [];
      }
      grouped[driverName]!.add(event);
    }

    return grouped;
  }
}

/// Geofence Notifier
class GeofenceNotifier extends StateNotifier<GeofenceState> {
  final TrackingApi _trackingApi;

  GeofenceNotifier(this._trackingApi) : super(GeofenceState());

  /// Fetch geofence events
  Future<void> fetchEvents({
    String? driverId,
    String? zoneId,
    DateTime? startTime,
    DateTime? endTime,
    bool loadMore = false,
  }) async {
    if (loadMore && !state.hasMore) {
      return; // No more data to load
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final page = loadMore ? state.currentPage + 1 : 1;

      final response = await _trackingApi.getGeofenceEvents(
        driverId: driverId,
        zoneId: zoneId,
        startTime: startTime,
        endTime: endTime,
        page: page,
        pageSize: 50,
      );

      final newEvents = loadMore
          ? [...state.events, ...response.events]
          : response.events;

      state = state.copyWith(
        events: newEvents,
        isLoading: false,
        lastFetch: DateTime.now(),
        currentPage: page,
        totalEvents: response.total,
        hasMore: response.hasNext,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Report a geofence event
  Future<void> reportEvent(GeofenceEventCreate event) async {
    try {
      await _trackingApi.createGeofenceEvent(event);

      // Optionally refresh events list
      await fetchEvents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load more events (pagination)
  Future<void> loadMore({
    String? driverId,
    String? zoneId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    await fetchEvents(
      driverId: driverId,
      zoneId: zoneId,
      startTime: startTime,
      endTime: endTime,
      loadMore: true,
    );
  }

  /// Refresh events (pull-to-refresh)
  Future<void> refresh({
    String? driverId,
    String? zoneId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    await fetchEvents(
      driverId: driverId,
      zoneId: zoneId,
      startTime: startTime,
      endTime: endTime,
      loadMore: false,
    );
  }

  /// Clear events
  void clear() {
    state = GeofenceState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Geofence Provider
final geofenceProvider =
    StateNotifierProvider<GeofenceNotifier, GeofenceState>(
  (ref) {
    final trackingApi = ref.watch(trackingApiProvider);
    return GeofenceNotifier(trackingApi);
  },
);
