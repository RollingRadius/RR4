import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/data/models/driver_model.dart';

/// Driver API Service
class DriverApi {
  final ApiService _apiService;

  DriverApi(this._apiService);

  /// Create a new driver
  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> driverData) async {
    try {
      print('📝 Creating driver with data: ${driverData['employee_id']}');
      print('🔑 Auth header: ${_apiService.dio.options.headers['Authorization']}');

      final response = await _apiService.dio.post(
        '/api/drivers',
        data: driverData,
      );

      print('✅ Driver created successfully');
      return response.data;
    } catch (e) {
      print('❌ Failed to create driver: $e');
      throw _apiService.handleError(e);
    }
  }

  /// Get list of drivers with optional filters
  Future<Map<String, dynamic>> getDrivers({
    int skip = 0,
    int limit = 50,
    String? status,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/drivers',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Get driver by ID
  Future<DriverModel> getDriverById(String driverId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/drivers/$driverId',
      );

      return DriverModel.fromJson(response.data);
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Update driver information
  Future<Map<String, dynamic>> updateDriver(
    String driverId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '/api/drivers/$driverId',
        data: updateData,
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Delete driver (soft delete)
  Future<Map<String, dynamic>> deleteDriver(String driverId) async {
    try {
      final response = await _apiService.dio.delete(
        '/api/drivers/$driverId',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Check driver's license expiry status
  Future<Map<String, dynamic>> checkLicenseExpiry(String driverId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/drivers/$driverId/license-status',
      );

      return response.data;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
