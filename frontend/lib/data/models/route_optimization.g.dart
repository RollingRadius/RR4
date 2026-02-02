// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_optimization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Waypoint _$WaypointFromJson(Map<String, dynamic> json) => Waypoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String?,
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WaypointToJson(Waypoint instance) => <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'address': instance.address,
      'order': instance.order,
    };

RouteOptimizeRequest _$RouteOptimizeRequestFromJson(
        Map<String, dynamic> json) =>
    RouteOptimizeRequest(
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RouteOptimizeRequestToJson(
        RouteOptimizeRequest instance) =>
    <String, dynamic>{
      'waypoints': instance.waypoints.map((e) => e.toJson()).toList(),
    };

RouteOptimizeResponse _$RouteOptimizeResponseFromJson(
        Map<String, dynamic> json) =>
    RouteOptimizeResponse(
      optimizedOrder: (json['optimized_order'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      optimizedWaypoints: (json['optimized_waypoints'] as List<dynamic>)
          .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistance: (json['total_distance'] as num).toDouble(),
      estimatedDuration: (json['estimated_duration'] as num).toInt(),
      geometry: json['geometry'] as String?,
    );

Map<String, dynamic> _$RouteOptimizeResponseToJson(
        RouteOptimizeResponse instance) =>
    <String, dynamic>{
      'optimized_order': instance.optimizedOrder,
      'optimized_waypoints':
          instance.optimizedWaypoints.map((e) => e.toJson()).toList(),
      'total_distance': instance.totalDistance,
      'estimated_duration': instance.estimatedDuration,
      'geometry': instance.geometry,
    };

RouteOptimization _$RouteOptimizationFromJson(Map<String, dynamic> json) =>
    RouteOptimization(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      optimizedRoute: (json['optimized_route'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      totalDistance: (json['total_distance'] as num?)?.toDouble(),
      estimatedDuration: (json['estimated_duration'] as num?)?.toInt(),
      createdBy: json['created_by'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RouteOptimizationToJson(RouteOptimization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organization_id': instance.organizationId,
      'name': instance.name,
      'waypoints': instance.waypoints,
      'optimized_route': instance.optimizedRoute,
      'total_distance': instance.totalDistance,
      'estimated_duration': instance.estimatedDuration,
      'created_by': instance.createdBy,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

RouteCreate _$RouteCreateFromJson(Map<String, dynamic> json) => RouteCreate(
      name: json['name'] as String,
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      optimizedRoute: (json['optimized_route'] as List<dynamic>?)
          ?.map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistance: (json['total_distance'] as num?)?.toDouble(),
      estimatedDuration: (json['estimated_duration'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'draft',
    );

Map<String, dynamic> _$RouteCreateToJson(RouteCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'waypoints': instance.waypoints.map((e) => e.toJson()).toList(),
      'optimized_route':
          instance.optimizedRoute?.map((e) => e.toJson()).toList(),
      'total_distance': instance.totalDistance,
      'estimated_duration': instance.estimatedDuration,
      'status': instance.status,
    };

RouteUpdate _$RouteUpdateFromJson(Map<String, dynamic> json) => RouteUpdate(
      name: json['name'] as String?,
      waypoints: (json['waypoints'] as List<dynamic>?)
          ?.map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      optimizedRoute: (json['optimized_route'] as List<dynamic>?)
          ?.map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistance: (json['total_distance'] as num?)?.toDouble(),
      estimatedDuration: (json['estimated_duration'] as num?)?.toInt(),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$RouteUpdateToJson(RouteUpdate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'waypoints': instance.waypoints?.map((e) => e.toJson()).toList(),
      'optimized_route':
          instance.optimizedRoute?.map((e) => e.toJson()).toList(),
      'total_distance': instance.totalDistance,
      'estimated_duration': instance.estimatedDuration,
      'status': instance.status,
    };

RouteListResponse _$RouteListResponseFromJson(Map<String, dynamic> json) =>
    RouteListResponse(
      routes: (json['routes'] as List<dynamic>)
          .map((e) => RouteOptimization.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      hasNext: (json['has_next'] as bool),
    );

Map<String, dynamic> _$RouteListResponseToJson(RouteListResponse instance) =>
    <String, dynamic>{
      'routes': instance.routes.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
      'has_next': instance.hasNext,
    };
