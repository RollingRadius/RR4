import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AvailableLoadsState {
  final List<LoadRequirementModel> loads;
  final bool isLoading;
  final bool isFulfilling;
  final String? error;
  final DateTime? lastUpdated;

  const AvailableLoadsState({
    this.loads = const [],
    this.isLoading = false,
    this.isFulfilling = false,
    this.error,
    this.lastUpdated,
  });

  AvailableLoadsState copyWith({
    List<LoadRequirementModel>? loads,
    bool? isLoading,
    bool? isFulfilling,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) =>
      AvailableLoadsState(
        loads: loads ?? this.loads,
        isLoading: isLoading ?? this.isLoading,
        isFulfilling: isFulfilling ?? this.isFulfilling,
        error: clearError ? null : (error ?? this.error),
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AvailableLoadsNotifier extends StateNotifier<AvailableLoadsState> {
  final ApiService _api;

  AvailableLoadsNotifier(this._api) : super(const AvailableLoadsState());

  /// Fetch all pending load requirements from all load_owner companies.
  Future<void> loadAvailableLoads({
    String? pickup,
    String? drop,
    String? material,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (pickup != null && pickup.isNotEmpty) params['pickup'] = pickup;
      if (drop != null && drop.isNotEmpty) params['drop'] = drop;
      if (material != null && material.isNotEmpty) params['material'] = material;

      final resp = await _api.dio.get('/api/loads/available', queryParameters: params);
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

  /// Silent background refresh.
  Future<void> silentRefresh() async {
    try {
      final resp = await _api.dio.get('/api/loads/available');
      final data = resp.data as Map<String, dynamic>;
      final loads = (data['loads'] as List<dynamic>? ?? [])
          .map((j) => LoadRequirementModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(loads: loads, lastUpdated: DateTime.now());
    } catch (_) {}
  }

  /// Fulfill a load requirement — creates a trip in the fleet org.
  /// Returns the created [TripModel] on success, null on failure.
  Future<TripModel?> fulfillLoad(
    String loadId, {
    String? vehicleId,
    String? driverId,
  }) async {
    state = state.copyWith(isFulfilling: true, clearError: true);
    try {
      final body = <String, dynamic>{
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (driverId != null) 'driver_id': driverId,
      };

      final resp = await _api.dio.post('/api/loads/$loadId/fulfill', data: body);
      final data = resp.data as Map<String, dynamic>;
      final trip = TripModel.fromJson(data['trip'] as Map<String, dynamic>);

      // Remove fulfilled load from list
      state = state.copyWith(
        loads: state.loads.where((l) => l.id != loadId).toList(),
        isFulfilling: false,
        lastUpdated: DateTime.now(),
      );
      return trip;
    } catch (e) {
      state = state.copyWith(
        error: _api.handleError(e),
        isFulfilling: false,
      );
      return null;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final availableLoadsProvider =
    StateNotifierProvider<AvailableLoadsNotifier, AvailableLoadsState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AvailableLoadsNotifier(api);
});
