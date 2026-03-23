import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class TripState {
  final List<TripModel> trips;
  final bool isLoading;     // true only on first load (shows shimmer)
  final bool isRefreshing;  // true on background poll (no shimmer)
  final String? error;
  final DateTime? lastUpdated;

  const TripState({
    this.trips = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
  });

  TripState copyWith({
    List<TripModel>? trips,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
  }) =>
      TripState(
        trips: trips ?? this.trips,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        error: error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  List<TripModel> get ongoingTrips =>
      trips.where((t) => t.isOngoing).toList();
  List<TripModel> get completedTrips =>
      trips.where((t) => t.isCompleted).toList();
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class TripNotifier extends StateNotifier<TripState> {
  final ApiService _apiService;

  TripNotifier(this._apiService) : super(const TripState());

  /// First load: shows full loading indicator.
  /// Subsequent background polls: silent refresh (isRefreshing only).
  Future<void> loadTrips({String? statusFilter, bool silent = false}) async {
    final firstLoad = state.trips.isEmpty && !silent;
    if (firstLoad) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isRefreshing: true, error: null);
    }

    try {
      final resp = await _apiService.dio.get(
        '/api/trips',
        queryParameters: {
          if (statusFilter != null) 'status': statusFilter,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      final trips = (data['trips'] as List<dynamic>? ?? [])
          .map((j) => TripModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        trips: trips,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: _apiService.handleError(e),
        isLoading: false,
        isRefreshing: false,
      );
    }
  }

  /// Called by the 30-second timer — never shows a loading indicator.
  Future<void> silentRefresh({String? statusFilter}) =>
      loadTrips(statusFilter: statusFilter, silent: true);

  Future<TripLocationModel?> fetchTripLocation(String tripId) async {
    try {
      final resp =
          await _apiService.dio.get('/api/trips/$tripId/vehicle-location');
      return TripLocationModel.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<TripModel?> createTrip(Map<String, dynamic> body) async {
    try {
      final resp =
          await _apiService.dio.post('/api/trips', data: body);
      final trip = TripModel.fromJson(resp.data as Map<String, dynamic>);
      state = state.copyWith(trips: [trip, ...state.trips]);
      return trip;
    } catch (e) {
      state = state.copyWith(error: _apiService.handleError(e));
      return null;
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final tripProvider =
    StateNotifierProvider<TripNotifier, TripState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return TripNotifier(api);
});
