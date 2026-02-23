import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/vehicle_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

final vehicleApiProvider = Provider<VehicleApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VehicleApi(apiService);
});

class VehicleState {
  final List<Map<String, dynamic>> vehicles;
  final bool isLoading;
  final String? error;

  const VehicleState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
  });

  VehicleState copyWith({
    List<Map<String, dynamic>>? vehicles,
    bool? isLoading,
    String? error,
  }) =>
      VehicleState(
        vehicles: vehicles ?? this.vehicles,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleApi _api;

  VehicleNotifier(this._api) : super(const VehicleState());

  Future<void> loadVehicles({String? statusFilter}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.getVehicles(statusFilter: statusFilter);
      final rawList = result['vehicles'] as List<dynamic>;
      final vehicles = rawList
          .map((v) => _mapVehicle(v as Map<String, dynamic>))
          .toList();
      state = state.copyWith(vehicles: vehicles, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      );
    }
  }

  Map<String, dynamic> _mapVehicle(Map<String, dynamic> v) {
    return {
      'id': v['id'] as String? ?? '',
      'vehicle_number': v['vehicle_number'] as String? ?? '',
      'registration': v['registration_number'] as String? ?? '',
      'make': v['manufacturer'] as String? ?? '',
      'model': v['model'] as String? ?? '',
      'year': v['year'] as int? ?? 0,
      'type': _capitalize(v['vehicle_type'] as String? ?? ''),
      'status': _capitalize(v['status'] as String? ?? ''),
      'driver': v['current_driver_name'] as String?,
      'mileage': (v['current_odometer'] as num?)?.toDouble() ?? 0.0,
      'fuelType': _capitalize(v['fuel_type'] as String? ?? ''),
      'vehicle_type': v['vehicle_type'] as String? ?? '',
    };
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  final api = ref.watch(vehicleApiProvider);
  return VehicleNotifier(api);
});
