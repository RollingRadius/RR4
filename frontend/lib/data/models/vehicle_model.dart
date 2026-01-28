class VehicleModel {
  final String id;
  final String registrationNumber;
  final String make;
  final String model;
  final int year;
  final String? vin;
  final String vehicleType;
  final String status;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final DateTime? lastServiceDate;
  final double? mileage;
  final String? fuelType;
  final String? color;
  final int? seatingCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    this.vin,
    required this.vehicleType,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
    this.lastServiceDate,
    this.mileage,
    this.fuelType,
    this.color,
    this.seatingCapacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      registrationNumber: json['registration_number'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      vin: json['vin'] as String?,
      vehicleType: json['vehicle_type'] as String,
      status: json['status'] as String,
      assignedDriverId: json['assigned_driver_id'] as String?,
      assignedDriverName: json['assigned_driver_name'] as String?,
      lastServiceDate: json['last_service_date'] != null
          ? DateTime.parse(json['last_service_date'] as String)
          : null,
      mileage: json['mileage'] != null ? (json['mileage'] as num).toDouble() : null,
      fuelType: json['fuel_type'] as String?,
      color: json['color'] as String?,
      seatingCapacity: json['seating_capacity'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'vehicle_type': vehicleType,
      'status': status,
      'assigned_driver_id': assignedDriverId,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'mileage': mileage,
      'fuel_type': fuelType,
      'color': color,
      'seating_capacity': seatingCapacity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName => '$make $model ($year)';

  bool get isActive => status.toLowerCase() == 'active';
  bool get isInMaintenance => status.toLowerCase() == 'maintenance';
  bool get isInactive => status.toLowerCase() == 'inactive';
}
