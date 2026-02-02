// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverLocation _$DriverLocationFromJson(Map<String, dynamic> json) =>
    DriverLocation(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      organizationId: json['organization_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      batteryLevel: (json['battery_level'] as num?)?.toInt(),
      isMockLocation: json['is_mock_location'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DriverLocationToJson(DriverLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver_id': instance.driverId,
      'organization_id': instance.organizationId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'altitude': instance.altitude,
      'speed': instance.speed,
      'heading': instance.heading,
      'battery_level': instance.batteryLevel,
      'is_mock_location': instance.isMockLocation,
      'timestamp': instance.timestamp.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

LocationCreate _$LocationCreateFromJson(Map<String, dynamic> json) =>
    LocationCreate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      batteryLevel: (json['battery_level'] as num?)?.toInt(),
      isMockLocation: json['is_mock_location'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$LocationCreateToJson(LocationCreate instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'altitude': instance.altitude,
      'speed': instance.speed,
      'heading': instance.heading,
      'battery_level': instance.batteryLevel,
      'is_mock_location': instance.isMockLocation,
      'timestamp': instance.timestamp.toIso8601String(),
    };

LocationBatchCreate _$LocationBatchCreateFromJson(Map<String, dynamic> json) =>
    LocationBatchCreate(
      locations: (json['locations'] as List<dynamic>)
          .map((e) => LocationCreate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationBatchCreateToJson(
        LocationBatchCreate instance) =>
    <String, dynamic>{
      'locations': instance.locations.map((e) => e.toJson()).toList(),
    };

LiveLocation _$LiveLocationFromJson(Map<String, dynamic> json) =>
    LiveLocation(
      driverId: json['driver_id'] as String,
      driverName: json['driver_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      batteryLevel: (json['battery_level'] as num?)?.toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      minutesSinceUpdate: (json['minutes_since_update'] as num).toInt(),
      isMoving: json['is_moving'] as bool,
    );

Map<String, dynamic> _$LiveLocationToJson(LiveLocation instance) =>
    <String, dynamic>{
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'speed': instance.speed,
      'heading': instance.heading,
      'battery_level': instance.batteryLevel,
      'timestamp': instance.timestamp.toIso8601String(),
      'minutes_since_update': instance.minutesSinceUpdate,
      'is_moving': instance.isMoving,
    };

LocationListResponse _$LocationListResponseFromJson(
        Map<String, dynamic> json) =>
    LocationListResponse(
      locations: (json['locations'] as List<dynamic>)
          .map((e) => DriverLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      hasNext: json['has_next'] as bool,
    );

Map<String, dynamic> _$LocationListResponseToJson(
        LocationListResponse instance) =>
    <String, dynamic>{
      'locations': instance.locations.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
      'has_next': instance.hasNext,
    };
