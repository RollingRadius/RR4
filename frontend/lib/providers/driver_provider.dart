import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/driver_api.dart';
import 'package:fleet_management/data/models/driver_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Driver API Provider
final driverApiProvider = Provider<DriverApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DriverApi(apiService);
});

/// Driver State
class DriverState {
  final List<DriverModel> drivers;
  final bool isLoading;
  final String? error;
  final DriverModel? selectedDriver;
  final int total;
  final String? statusFilter;

  DriverState({
    this.drivers = const [],
    this.isLoading = false,
    this.error,
    this.selectedDriver,
    this.total = 0,
    this.statusFilter,
  });

  DriverState copyWith({
    List<DriverModel>? drivers,
    bool? isLoading,
    String? error,
    DriverModel? selectedDriver,
    int? total,
    String? statusFilter,
  }) {
    return DriverState(
      drivers: drivers ?? this.drivers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDriver: selectedDriver ?? this.selectedDriver,
      total: total ?? this.total,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

/// Driver Notifier
class DriverNotifier extends StateNotifier<DriverState> {
  final DriverApi _driverApi;

  DriverNotifier(this._driverApi) : super(DriverState());

  /// Load drivers with optional status filter
  Future<void> loadDrivers({String? status}) async {
    state = state.copyWith(isLoading: true, error: null, statusFilter: status);

    try {
      final response = await _driverApi.getDrivers(
        skip: 0,
        limit: 100,
        status: status,
      );

      final List<dynamic> driversJson = response['drivers'];
      final drivers = driversJson
          .map((json) => DriverModel.fromJson(json))
          .toList();

      state = state.copyWith(
        drivers: drivers,
        total: response['total'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add new driver
  Future<bool> addDriver(Map<String, dynamic> driverData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _driverApi.createDriver(driverData);

      // Reload drivers list
      await loadDrivers(status: state.statusFilter);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Get driver by ID
  Future<DriverModel?> getDriverById(String driverId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final driver = await _driverApi.getDriverById(driverId);

      state = state.copyWith(
        selectedDriver: driver,
        isLoading: false,
      );

      return driver;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update driver
  Future<bool> updateDriver(String driverId, Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _driverApi.updateDriver(driverId, updateData);

      // Reload drivers list
      await loadDrivers(status: state.statusFilter);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete driver
  Future<bool> deleteDriver(String driverId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _driverApi.deleteDriver(driverId);

      // Remove from local list
      final updatedDrivers = state.drivers
          .where((driver) => driver.driverId != driverId)
          .toList();

      state = state.copyWith(
        drivers: updatedDrivers,
        total: state.total - 1,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check license expiry
  Future<Map<String, dynamic>?> checkLicenseExpiry(String driverId) async {
    try {
      final result = await _driverApi.checkLicenseExpiry(driverId);
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Filter drivers by status locally
  void filterDriversByStatus(String? status) {
    state = state.copyWith(statusFilter: status);
    loadDrivers(status: status);
  }

  /// Get drivers with expiring licenses
  List<DriverModel> get driversWithExpiringLicenses {
    return state.drivers
        .where((driver) => driver.hasExpiringSoonLicense)
        .toList();
  }

  /// Get drivers with expired licenses
  List<DriverModel> get driversWithExpiredLicenses {
    return state.drivers
        .where((driver) => driver.hasExpiredLicense)
        .toList();
  }

  /// Get active drivers count
  int get activeDriversCount {
    return state.drivers.where((driver) => driver.isActive).length;
  }

  /// Select driver
  void selectDriver(DriverModel driver) {
    state = state.copyWith(selectedDriver: driver);
  }

  /// Clear selected driver
  void clearSelectedDriver() {
    state = state.copyWith(selectedDriver: null);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Driver Provider
final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  final driverApi = ref.watch(driverApiProvider);
  return DriverNotifier(driverApi);
});
