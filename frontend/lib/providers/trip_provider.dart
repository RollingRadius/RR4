import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// How many trips a fleet-status list shows when nobody is searching.
const int kLatestTripsShown = 20;

// ─── State ────────────────────────────────────────────────────────────────────

class TripState {
  final List<TripModel> trips;
  final bool isLoading;     // true only on first load (shows shimmer)
  final bool isRefreshing;  // true on background poll (no shimmer)
  final String? error;
  final DateTime? lastUpdated;
  /// Number of active (ongoing + pending) trips in the whole fleet-status list, not just the ones loaded.
  /// Null until an active list has loaded without a search.
  final int? activeTotal;

  const TripState({
    this.trips = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
    this.activeTotal,
  });

  TripState copyWith({
    List<TripModel>? trips,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
    int? activeTotal,
  }) =>
      TripState(
        trips: trips ?? this.trips,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        error: error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        activeTotal: activeTotal ?? this.activeTotal,
      );

  List<TripModel> get ongoingTrips =>
      trips.where((t) => t.isOngoing).toList();
  /// All trips that are actively being worked on (pending + ongoing).
  /// Used by the fleet manager dashboard.
  List<TripModel> get activeTrips =>
      trips.where((t) => t.isOngoing || t.isPending).toList();
  List<TripModel> get completedTrips =>
      trips.where((t) => t.isCompleted).toList();
  List<TripModel> get cancelledTrips =>
      trips.where((t) => t.isCancelled).toList();
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class TripNotifier extends StateNotifier<TripState> {
  final ApiService _apiService;

  TripNotifier(this._apiService) : super(const TripState());

  /// Fleet-status lists open on the newest [kLatestTripsShown] trips; older ones are reached by search.
  static const int _searchResultLimit = 200; // the endpoint's maximum

  // The dashboards' two search boxes. Kept here (not in the screens) so every refresh of the active
  // list — the 30s poll, pull-to-refresh, "refresh after an action" — keeps asking for the same search.
  String _query = '';
  String _bilty = '';
  Timer? _debounce;
  int _requestSeq = 0;

  static bool _isActiveList(String? statusFilter, bool rrOnly) =>
      !rrOnly &&
      statusFilter != null &&
      statusFilter.split(',').every((s) => s.trim() == 'ongoing' || s.trim() == 'pending');

  /// Search the active list on the server (trip number / RR trip number, and Stage 4 bilty number),
  /// after a short pause in typing. Empty strings go back to the newest [kLatestTripsShown].
  void setSearch({required String query, required String bilty, bool rrWeb = false}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      loadTrips(statusFilter: 'ongoing,pending', rrWeb: rrWeb, query: query, bilty: bilty, silent: true);
    });
  }

  /// Forget the search without a request (the next refresh of the list is unfiltered). Called when a
  /// dashboard goes away, so other screens reading this list are not left holding search results.
  void clearSearch() {
    _debounce?.cancel();
    _query = '';
    _bilty = '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// First load: shows full loading indicator.
  /// Subsequent background polls: silent refresh (isRefreshing only).
  ///
  /// For an ongoing/pending list, [query] / [bilty] replace the remembered search (null keeps it).
  Future<void> loadTrips({
    String? statusFilter,
    bool rrOnly = false,
    bool rrWeb = false,
    bool silent = false,
    String? query,
    String? bilty,
  }) async {
    final activeList = _isActiveList(statusFilter, rrOnly);
    if (activeList) {
      if (query != null) _query = query.trim();
      if (bilty != null) _bilty = bilty.trim();
    }
    final searching = activeList && (_query.isNotEmpty || _bilty.isNotEmpty);

    final firstLoad = state.trips.isEmpty && !silent && !searching;
    if (firstLoad) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isRefreshing: true, error: null);
    }

    final seq = ++_requestSeq;
    try {
      final resp = await _apiService.dio.get(
        '/api/trips',
        queryParameters: {
          if (statusFilter != null) 'status': statusFilter,
          if (rrOnly) 'rr_only': true,
          if (rrWeb) 'rr_web': true,
          if (activeList) 'limit': searching ? _searchResultLimit : kLatestTripsShown,
          if (searching && _query.isNotEmpty) 'q': _query,
          if (searching && _bilty.isNotEmpty) 'bilty': _bilty,
        },
      );
      if (seq != _requestSeq || !mounted) return; // a newer request (e.g. more typing) supersedes this one
      final data = resp.data as Map<String, dynamic>;
      final trips = (data['trips'] as List<dynamic>? ?? [])
          .map((j) => TripModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        trips: trips,
        // the header count: every active trip, which a search result is not
        activeTotal: activeList && !searching ? (data['total'] as num?)?.toInt() ?? trips.length : null,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (seq != _requestSeq || !mounted) return;
      state = state.copyWith(
        error: _apiService.handleError(e),
        isLoading: false,
        isRefreshing: false,
      );
    }
  }

  /// Called by the 30-second timer — never shows a loading indicator.
  Future<void> silentRefresh({String? statusFilter, bool rrOnly = false, bool rrWeb = false}) =>
      loadTrips(statusFilter: statusFilter, rrOnly: rrOnly, rrWeb: rrWeb, silent: true);

  /// Cancel a trip (soft-cancel: status → 'cancelled', record kept in DB).
  /// The cancelled trip will appear in the Cancelled filter on the dashboard.
  /// Returns true on success.
  Future<bool> cancelTrip(String tripId) async {
    try {
      final resp = await _apiService.dio.patch('/api/trips/$tripId/cancel');
      final updated = TripModel.fromJson(
          (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>);
      patchTrip(updated);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Trip no longer exists server-side — remove from local state silently.
        state = state.copyWith(
          trips: state.trips.where((t) => t.id != tripId).toList(),
        );
        return true;
      }
      state = state.copyWith(error: _apiService.handleError(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: _apiService.handleError(e));
      return false;
    }
  }

  /// Replace one trip in the in-memory list without hitting the API.
  void patchTrip(TripModel updated) {
    final exists = state.trips.any((t) => t.id == updated.id);
    state = state.copyWith(
      trips: exists
          ? state.trips.map((t) => t.id == updated.id ? updated : t).toList()
          : [updated, ...state.trips],
      lastUpdated: DateTime.now(),
    );
  }

  /// Mark a trip as completed (LP owner only). Returns true on success.
  Future<bool> completeTrip(String tripId) async {
    try {
      final resp = await _apiService.dio.post('/api/trips/$tripId/complete');
      final updated = TripModel.fromJson(
          (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>);
      patchTrip(updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: _apiService.handleError(e));
      return false;
    }
  }

  /// Fetch one trip from the API and patch the list silently.
  Future<void> fetchSingleTrip(String tripId) async {
    try {
      final resp = await _apiService.dio.get('/api/trips/$tripId');
      patchTrip(TripModel.fromJson(resp.data as Map<String, dynamic>));
    } catch (_) {}
  }

  Future<TripLocationModel?> fetchTripLocation(String tripId) async {
    try {
      final resp =
          await _apiService.dio.get('/api/trips/$tripId/vehicle-location');
      return TripLocationModel.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// The driver's actual travelled path for this trip (every GPS ping
  /// tagged with this trip, oldest to newest) plus the "location was off"
  /// gaps in it — see GET .../driver-trail.
  Future<DriverTrail> fetchDriverTrail(String tripId) async {
    try {
      final resp =
          await _apiService.dio.get('/api/trips/$tripId/driver-trail');
      return DriverTrail.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return const DriverTrail();
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

/// Separate provider for completed trips — used by LP Records tab.
/// Keeps completed trips isolated from the active-trips list in tripProvider.
final completedTripsProvider =
    StateNotifierProvider<TripNotifier, TripState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return TripNotifier(api);
});

/// Holds the RR trip number to show as a success popup on the LP dashboard
/// after trip creation. Set by CreateTripScreen, consumed + cleared by LP dashboard.
final pendingRrTripNumberProvider = StateProvider<String?>((ref) => null);

/// Local trip ID for the just-created trip, set alongside
/// [pendingRrTripNumberProvider] — used to show the "Allow Field Executive to
/// fill S1 docs?" follow-up popup right after the trip-number popup closes.
final pendingCreatedTripIdProvider = StateProvider<String?>((ref) => null);
