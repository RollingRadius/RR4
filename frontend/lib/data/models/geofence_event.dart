import 'package:json_annotation/json_annotation.dart';

part 'geofence_event.g.dart';

/// Model representing a geofence event (enter/exit)
@JsonSerializable()
class GeofenceEvent {
  final String id;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'driver_name')
  final String driverName;
  @JsonKey(name: 'zone_id')
  final String zoneId;
  @JsonKey(name: 'zone_name')
  final String zoneName;
  @JsonKey(name: 'organization_id')
  final String organizationId;
  @JsonKey(name: 'event_type')
  final String eventType; // 'enter' or 'exit'
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  GeofenceEvent({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.zoneId,
    required this.zoneName,
    required this.organizationId,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.createdAt,
  });

  factory GeofenceEvent.fromJson(Map<String, dynamic> json) =>
      _$GeofenceEventFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceEventToJson(this);

  bool get isEnter => eventType == 'enter';
  bool get isExit => eventType == 'exit';
}

/// Model for creating a geofence event
@JsonSerializable()
class GeofenceEventCreate {
  @JsonKey(name: 'zone_id')
  final String zoneId;
  @JsonKey(name: 'event_type')
  final String eventType;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  @JsonKey(name: 'location_id')
  final String? locationId;

  GeofenceEventCreate({
    required this.zoneId,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.locationId,
  });

  factory GeofenceEventCreate.fromJson(Map<String, dynamic> json) =>
      _$GeofenceEventCreateFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceEventCreateToJson(this);
}

/// Model for paginated geofence event list
@JsonSerializable()
class GeofenceEventListResponse {
  final List<GeofenceEvent> events;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;
  @JsonKey(name: 'has_next')
  final bool hasNext;

  GeofenceEventListResponse({
    required this.events,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasNext,
  });

  factory GeofenceEventListResponse.fromJson(Map<String, dynamic> json) =>
      _$GeofenceEventListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceEventListResponseToJson(this);
}
