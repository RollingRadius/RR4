import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class LoadState {
  final List<LoadRequirementModel> loads;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final DateTime? lastUpdated;

  const LoadState({
    this.loads = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.lastUpdated,
  });

  LoadState copyWith({
    List<LoadRequirementModel>? loads,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) =>
      LoadState(
        loads: loads ?? this.loads,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class LoadNotifier extends StateNotifier<LoadState> {
  final ApiService _api;

  LoadNotifier(this._api) : super(const LoadState());

  /// Fetch all load requirements for the current user's company.
  Future<void> loadLoads() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _api.dio.get('/api/loads');
      final data = resp.data as Map<String, dynamic>;
      final loads = (data['loads'] as List<dynamic>? ?? [])
          .map((j) => LoadRequirementModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        loads: loads,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: _api.handleError(e),
        isLoading: false,
      );
    }
  }

  /// Silent background refresh (no loading spinner).
  Future<void> silentRefresh() async {
    try {
      final resp = await _api.dio.get('/api/loads');
      final data = resp.data as Map<String, dynamic>;
      final loads = (data['loads'] as List<dynamic>? ?? [])
          .map((j) => LoadRequirementModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(loads: loads, lastUpdated: DateTime.now());
    } catch (_) {
      // silent — don't update error state
    }
  }

  /// Submit a new manual load requirement. Returns the created model on
  /// success, null on failure (error stored in state).
  Future<LoadRequirementModel?> createLoad({
    required String pickupLocation,
    required String unloadLocation,
    required String materialType,
    required String entryDate,
    required int truckCount,
    String? capacity,
    String? axelType,
    String? bodyType,
    String? floorType,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final body = <String, dynamic>{
        'entry_method': 'manual',
        'pickup_location': pickupLocation,
        'unload_location': unloadLocation,
        'material_type': materialType,
        'entry_date': entryDate,
        'truck_count': truckCount,
        if (capacity != null || axelType != null || bodyType != null || floorType != null)
          'specifications': {
            if (capacity != null) 'capacity': capacity,
            if (axelType != null) 'axel_type': axelType,
            if (bodyType != null) 'body': bodyType,
            if (floorType != null) 'floor': floorType,
          },
      };

      final resp = await _api.dio.post('/api/loads', data: body);
      final data = resp.data as Map<String, dynamic>;
      final load = LoadRequirementModel.fromJson(
          data['load'] as Map<String, dynamic>);

      // Prepend to local list
      state = state.copyWith(
        loads: [load, ...state.loads],
        isSubmitting: false,
        lastUpdated: DateTime.now(),
      );
      return load;
    } catch (e) {
      state = state.copyWith(
        error: _api.handleError(e),
        isSubmitting: false,
      );
      return null;
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final loadProvider = StateNotifierProvider<LoadNotifier, LoadState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return LoadNotifier(api);
});
