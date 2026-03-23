class TripModel {
  final String id;
  final String tripNumber;
  final String? biltyNumber;
  final String origin;
  final String? originSub;
  final String destination;
  final String? destinationSub;
  final String loadItem;
  final String? weight;
  final double? tripAmount;
  final String? invoiceNumber;
  final String status;
  final String organizationId;
  final String? loadOwnerOrgId;
  final String? vehicleId;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? driverId;
  final String? driverName;
  final String? startDate;
  final String? endDate;
  final String? createdAt;

  const TripModel({
    required this.id,
    required this.tripNumber,
    this.biltyNumber,
    required this.origin,
    this.originSub,
    required this.destination,
    this.destinationSub,
    required this.loadItem,
    this.weight,
    this.tripAmount,
    this.invoiceNumber,
    required this.status,
    required this.organizationId,
    this.loadOwnerOrgId,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleModel,
    this.driverId,
    this.driverName,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  bool get isOngoing => status == 'ongoing';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasVehicle => vehicleId != null;

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      tripNumber: json['trip_number'] as String,
      biltyNumber: json['bilty_number'] as String?,
      origin: json['origin'] as String,
      originSub: json['origin_sub'] as String?,
      destination: json['destination'] as String,
      destinationSub: json['destination_sub'] as String?,
      loadItem: json['load_item'] as String,
      weight: json['weight'] as String?,
      tripAmount: (json['trip_amount'] as num?)?.toDouble(),
      invoiceNumber: json['invoice_number'] as String?,
      status: json['status'] as String? ?? 'ongoing',
      organizationId: json['organization_id'] as String,
      loadOwnerOrgId: json['load_owner_org_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class TripLocationModel {
  final String tripId;
  final String tripNumber;
  final String? vehicleId;
  final String? driverId;
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? heading;
  final String? timestamp;
  final String? message;

  const TripLocationModel({
    required this.tripId,
    required this.tripNumber,
    this.vehicleId,
    this.driverId,
    required this.hasLocation,
    this.latitude,
    this.longitude,
    this.speed,
    this.heading,
    this.timestamp,
    this.message,
  });

  factory TripLocationModel.fromJson(Map<String, dynamic> json) {
    return TripLocationModel(
      tripId: json['trip_id'] as String,
      tripNumber: json['trip_number'] as String,
      vehicleId: json['vehicle_id'] as String?,
      driverId: json['driver_id'] as String?,
      hasLocation: json['has_location'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String?,
      message: json['message'] as String?,
    );
  }
}
