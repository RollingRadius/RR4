import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/rr_sync_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class RrSyncState {
  final List<Map<String, dynamic>> readyTrips;
  final List<Map<String, dynamic>> missingDataTrips;
  final int readyCount;
  final bool isLoading;
  final String? syncingTripId; // which trip is currently being synced
  final String? error;
  final String? successMessage;

  const RrSyncState({
    this.readyTrips = const [],
    this.missingDataTrips = const [],
    this.readyCount = 0,
    this.isLoading = false,
    this.syncingTripId,
    this.error,
    this.successMessage,
  });

  RrSyncState copyWith({
    List<Map<String, dynamic>>? readyTrips,
    List<Map<String, dynamic>>? missingDataTrips,
    int? readyCount,
    bool? isLoading,
    Object? syncingTripId = _keep,
    Object? error = _keep,
    Object? successMessage = _keep,
  }) =>
      RrSyncState(
        readyTrips: readyTrips ?? this.readyTrips,
        missingDataTrips: missingDataTrips ?? this.missingDataTrips,
        readyCount: readyCount ?? this.readyCount,
        isLoading: isLoading ?? this.isLoading,
        syncingTripId: syncingTripId == _keep ? this.syncingTripId : syncingTripId as String?,
        error: error == _keep ? this.error : error as String?,
        successMessage: successMessage == _keep ? this.successMessage : successMessage as String?,
      );

static const Object _keep = Object();
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class RrSyncNotifier extends StateNotifier<RrSyncState> {
  final RrSyncApi _api;

  RrSyncNotifier(this._api) : super(const RrSyncState());

  Future<void> loadReadyTrips() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.getReadyTrips();
      final ready = List<Map<String, dynamic>>.from(
        (data['ready'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
      );
      final missing = List<Map<String, dynamic>>.from(
        (data['missing_data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
      );
      state = state.copyWith(
        readyTrips: ready,
        missingDataTrips: missing,
        readyCount: data['ready_count'] as int? ?? ready.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load sync status: $e',
      );
    }
  }

  Future<void> syncTrip(String tripId, String rrToken) async {
    state = state.copyWith(syncingTripId: tripId);
    try {
      await _api.triggerTripSync(tripId, rrToken);
      await loadReadyTrips();
      state = state.copyWith(
        syncingTripId: null,
        successMessage: 'Sync started — check back shortly',
      );
    } catch (e) {
      state = state.copyWith(
        syncingTripId: null,
        error: 'Sync failed: $e',
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final rrSyncApiProvider = Provider<RrSyncApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RrSyncApi(apiService);
});

final rrSyncProvider = StateNotifierProvider<RrSyncNotifier, RrSyncState>((ref) {
  return RrSyncNotifier(ref.watch(rrSyncApiProvider));
});
