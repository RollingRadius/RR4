import 'package:json_annotation/json_annotation.dart';

part 'route_optimization.g.dart';

/// Model representing a waypoint in a route
@JsonSerializable()
class Waypoint {
  final double lat;
  final double lng;
  final String? address;
  final int? order;

  Waypoint({
    required this.lat,
    required this.lng,
    this.address,
    this.order,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) =>
      _$WaypointFromJson(json);

  Map<String, dynamic> toJson() => _$WaypointToJson(this);

  Waypoint copyWith({
    double? lat,
    double? lng,
    String? address,
    int? order,
  }) {
    return Waypoint(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      order: order ?? this.order,
    );
  }
}

/// Model for route optimization request
@JsonSerializable()
class RouteOptimizeRequest {
  final List<Waypoint> waypoints;

  RouteOptimizeRequest({required this.waypoints});

  factory RouteOptimizeRequest.fromJson(Map<String, dynamic> json) =>
      _$RouteOptimizeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RouteOptimizeRequestToJson(this);
}

/// Model for route optimization response
@JsonSerializable()
class RouteOptimizeResponse {
  @JsonKey(name: 'optimized_order')
  final List<int> optimizedOrder;
  @JsonKey(name: 'optimized_waypoints')
  final List<Waypoint> optimizedWaypoints;
  @JsonKey(name: 'total_distance')
  final double totalDistance; // in km
  @JsonKey(name: 'estimated_duration')
  final int estimatedDuration; // in minutes
  final String? geometry; // encoded polyline

  RouteOptimizeResponse({
    required this.optimizedOrder,
    required this.optimizedWaypoints,
    required this.totalDistance,
    required this.estimatedDuration,
    this.geometry,
  });

  factory RouteOptimizeResponse.fromJson(Map<String, dynamic> json) =>
      _$RouteOptimizeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RouteOptimizeResponseToJson(this);
}

/// Model for saved route
@JsonSerializable()
class RouteOptimization {
  final String id;
  @JsonKey(name: 'organization_id')
  final String organizationId;
  final String name;
  final List<Map<String, dynamic>> waypoints;
  @JsonKey(name: 'optimized_route')
  final List<Map<String, dynamic>>? optimizedRoute;
  @JsonKey(name: 'total_distance')
  final double? totalDistance;
  @JsonKey(name: 'estimated_duration')
  final int? estimatedDuration;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  RouteOptimization({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.waypoints,
    this.optimizedRoute,
    this.totalDistance,
    this.estimatedDuration,
    this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteOptimization.fromJson(Map<String, dynamic> json) =>
      _$RouteOptimizationFromJson(json);

  Map<String, dynamic> toJson() => _$RouteOptimizationToJson(this);

  bool get isOptimized => optimizedRoute != null;

  List<Waypoint> get waypointsList {
    return waypoints
        .map((w) => Waypoint.fromJson(w))
        .toList();
  }

  List<Waypoint>? get optimizedWaypointsList {
    return optimizedRoute
        ?.map((w) => Waypoint.fromJson(w))
        .toList();
  }
}

/// Model for creating a route
@JsonSerializable()
class RouteCreate {
  final String name;
  final List<Waypoint> waypoints;
  @JsonKey(name: 'optimized_route')
  final List<Waypoint>? optimizedRoute;
  @JsonKey(name: 'total_distance')
  final double? totalDistance;
  @JsonKey(name: 'estimated_duration')
  final int? estimatedDuration;
  final String? status;

  RouteCreate({
    required this.name,
    required this.waypoints,
    this.optimizedRoute,
    this.totalDistance,
    this.estimatedDuration,
    this.status = 'draft',
  });

  factory RouteCreate.fromJson(Map<String, dynamic> json) =>
      _$RouteCreateFromJson(json);

  Map<String, dynamic> toJson() => _$RouteCreateToJson(this);
}

/// Model for updating a route
@JsonSerializable()
class RouteUpdate {
  final String? name;
  final List<Waypoint>? waypoints;
  @JsonKey(name: 'optimized_route')
  final List<Waypoint>? optimizedRoute;
  @JsonKey(name: 'total_distance')
  final double? totalDistance;
  @JsonKey(name: 'estimated_duration')
  final int? estimatedDuration;
  final String? status;

  RouteUpdate({
    this.name,
    this.waypoints,
    this.optimizedRoute,
    this.totalDistance,
    this.estimatedDuration,
    this.status,
  });

  factory RouteUpdate.fromJson(Map<String, dynamic> json) =>
      _$RouteUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$RouteUpdateToJson(this);
}

/// Model for paginated route list
@JsonSerializable()
class RouteListResponse {
  final List<RouteOptimization> routes;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;
  @JsonKey(name: 'has_next')
  final bool hasNext;

  RouteListResponse({
    required this.routes,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasNext,
  });

  factory RouteListResponse.fromJson(Map<String, dynamic> json) =>
      _$RouteListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RouteListResponseToJson(this);
}
