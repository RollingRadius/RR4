import 'package:dio/dio.dart';
import 'package:fleet_management/data/services/api_service.dart';

class VehicleApi {
  final ApiService _apiService;

  VehicleApi(this._apiService);

  Dio get _dio => _apiService.dio;

  /// Get list of vehicles
  Future<Map<String, dynamic>> getVehicles({
    String? statusFilter,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/api/vehicles',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (statusFilter != null) 'status': statusFilter,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Create a new vehicle
  Future<Map<String, dynamic>> createVehicle({
    required String vehicleNumber,
    required String registrationNumber,
    required String manufacturer,
    required String model,
    required int year,
    required String vehicleType,
    required String fuelType,
    int currentOdometer = 0,
    String? vinNumber,
  }) async {
    try {
      final data = <String, dynamic>{
        'vehicle_number': vehicleNumber,
        'registration_number': registrationNumber,
        'manufacturer': manufacturer,
        'model': model,
        'year': year,
        'vehicle_type': vehicleType,
        'fuel_type': fuelType,
        'current_odometer': currentOdometer,
        if (vinNumber != null && vinNumber.isNotEmpty)
          'vin_number': vinNumber,
      };

      final response = await _dio.post('/api/vehicles', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }

  /// Upload a photo for a vehicle
  Future<Map<String, dynamic>> uploadVehiclePhoto({
    required String vehicleId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/api/vehicles/$vehicleId/photo',
        data: formData,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _apiService.handleError(e);
    }
  }
}
