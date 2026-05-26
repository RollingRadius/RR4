import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/rr_sync_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class RrSyncState {
  final List<Map<String, dynamic>> readyTrips;
  final List<Map<String, dynamic>> missingDataTrips;
  final int readyCount;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final String? successMessage;

  const RrSyncState({
    this.readyTrips = const [],
    this.missingDataTrips = const [],
    this.readyCount = 0,
    this.selectedIds = const {},
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.successMessage,
  });

  RrSyncState copyWith({
    List<Map<String, dynamic>>? readyTrips,
    List<Map<String, dynamic>>? missingDataTrips,
    int? readyCount,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    String? successMessage,
  }) =>
      RrSyncState(
        readyTrips: readyTrips ?? this.readyTrips,
        missingDataTrips: missingDataTrips ?? this.missingDataTrips,
        readyCount: readyCount ?? this.readyCount,
        selectedIds: selectedIds ?? this.selectedIds,
        isLoading: isLoading ?? this.isLoading,
        isSyncing: isSyncing ?? this.isSyncing,
        error: error,
        successMessage: successMessage,
      );
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
        selectedIds: {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load sync status: $e',
      );
    }
  }

  void toggleSelection(String tripId) {
    final current = Set<String>.from(state.selectedIds);
    if (current.contains(tripId)) {
      current.remove(tripId);
    } else {
      current.add(tripId);
    }
    state = state.copyWith(selectedIds: current);
  }

  void selectAll() {
    final allIds = state.readyTrips.map((t) => t['trip_id'] as String).toSet();
    state = state.copyWith(selectedIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> syncSelected() async {
    if (state.selectedIds.isEmpty) return;
    state = state.copyWith(isSyncing: true);
    try {
      final result = await _api.triggerBulkSync(state.selectedIds.toList());
      final queued = (result['queued'] as List? ?? []).length;
      final skipped = (result['skipped'] as List? ?? []).length;
      final msg = '$queued trip(s) queued for sync'
          '${skipped > 0 ? ', $skipped skipped' : ''}';
      // Reload list to reflect updated statuses
      await loadReadyTrips();
      state = state.copyWith(isSyncing: false, successMessage: msg);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
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
