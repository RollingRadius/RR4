// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geofence_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeofenceEvent _$GeofenceEventFromJson(Map<String, dynamic> json) =>
    GeofenceEvent(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      driverName: json['driver_name'] as String,
      zoneId: json['zone_id'] as String,
      zoneName: json['zone_name'] as String,
      organizationId: json['organization_id'] as String,
      eventType: json['event_type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$GeofenceEventToJson(GeofenceEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'zone_id': instance.zoneId,
      'zone_name': instance.zoneName,
      'organization_id': instance.organizationId,
      'event_type': instance.eventType,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

GeofenceEventCreate _$GeofenceEventCreateFromJson(Map<String, dynamic> json) =>
    GeofenceEventCreate(
      zoneId: json['zone_id'] as String,
      eventType: json['event_type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      locationId: json['location_id'] as String?,
    );

Map<String, dynamic> _$GeofenceEventCreateToJson(
        GeofenceEventCreate instance) =>
    <String, dynamic>{
      'zone_id': instance.zoneId,
      'event_type': instance.eventType,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'location_id': instance.locationId,
    };

GeofenceEventListResponse _$GeofenceEventListResponseFromJson(
        Map<String, dynamic> json) =>
    GeofenceEventListResponse(
      events: (json['events'] as List<dynamic>)
          .map((e) => GeofenceEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      hasNext: json['has_next'] as bool,
    );

Map<String, dynamic> _$GeofenceEventListResponseToJson(
        GeofenceEventListResponse instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
      'has_next': instance.hasNext,
    };
