import 'package:json_annotation/json_annotation.dart';

part 'driver_location.g.dart';

/// Model representing a GPS location point for a driver
@JsonSerializable()
class DriverLocation {
  final String id;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'organization_id')
  final String organizationId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  @JsonKey(name: 'battery_level')
  final int? batteryLevel;
  @JsonKey(name: 'is_mock_location')
  final bool isMockLocation;
  final DateTime timestamp;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  DriverLocation({
    required this.id,
    required this.driverId,
    required this.organizationId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.batteryLevel,
    this.isMockLocation = false,
    required this.timestamp,
    required this.createdAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) =>
      _$DriverLocationFromJson(json);

  Map<String, dynamic> toJson() => _$DriverLocationToJson(this);
}

/// Model for creating a location record
@JsonSerializable()
class LocationCreate {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  @JsonKey(name: 'battery_level')
  final int? batteryLevel;
  @JsonKey(name: 'is_mock_location')
  final bool isMockLocation;
  final DateTime timestamp;

  LocationCreate({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.batteryLevel,
    this.isMockLocation = false,
    required this.timestamp,
  });

  factory LocationCreate.fromJson(Map<String, dynamic> json) =>
      _$LocationCreateFromJson(json);

  Map<String, dynamic> toJson() => _$LocationCreateToJson(this);
}

/// Model for batch location creation
@JsonSerializable()
class LocationBatchCreate {
  final List<LocationCreate> locations;

  LocationBatchCreate({required this.locations});

  factory LocationBatchCreate.fromJson(Map<String, dynamic> json) =>
      _$LocationBatchCreateFromJson(json);

  Map<String, dynamic> toJson() => _$LocationBatchCreateToJson(this);
}

/// Model for live location with driver info
@JsonSerializable()
class LiveLocation {
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'driver_name')
  final String driverName;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  @JsonKey(name: 'battery_level')
  final int? batteryLevel;
  final DateTime timestamp;
  @JsonKey(name: 'minutes_since_update')
  final int minutesSinceUpdate;
  @JsonKey(name: 'is_moving')
  final bool isMoving;

  LiveLocation({
    required this.driverId,
    required this.driverName,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.batteryLevel,
    required this.timestamp,
    required this.minutesSinceUpdate,
    required this.isMoving,
  });

  factory LiveLocation.fromJson(Map<String, dynamic> json) =>
      _$LiveLocationFromJson(json);

  Map<String, dynamic> toJson() => _$LiveLocationToJson(this);

  /// Get status based on last update time
  LocationStatus get status {
    if (minutesSinceUpdate < 5 && isMoving) {
      return LocationStatus.active;
    } else if (minutesSinceUpdate < 5) {
      return LocationStatus.idle;
    } else {
      return LocationStatus.offline;
    }
  }
}

/// Location status enum
enum LocationStatus {
  active,
  idle,
  offline,
}

/// Model for paginated location list response
@JsonSerializable()
class LocationListResponse {
  final List<DriverLocation> locations;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;
  @JsonKey(name: 'has_next')
  final bool hasNext;

  LocationListResponse({
    required this.locations,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasNext,
  });

  factory LocationListResponse.fromJson(Map<String, dynamic> json) =>
      _$LocationListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LocationListResponseToJson(this);
}
