"""
GPS Tracking API Router
Endpoints for location tracking, geofencing, and route optimization
"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.driver import Driver
from app.models.tracking import RouteOptimization
from app.services.tracking_service import TrackingService
from app.schemas.tracking import (
    LocationCreate,
    LocationBatchCreate,
    LocationResponse,
    LocationListResponse,
    LiveLocationResponse,
    GeofenceEventCreate,
    GeofenceEventResponse,
    GeofenceEventListResponse,
    RouteOptimizeRequest,
    RouteOptimizeResponse,
    RouteCreate,
    RouteUpdate,
    RouteResponse,
    RouteListResponse,
    DriverTrackingUpdate,
    DriverTrackingStatusResponse,
    TrackingAnalyticsSummary
)
from app.api.v1.auth import get_current_user
from app.services.capability_service import CapabilityService

router = APIRouter(prefix="/tracking", tags=["GPS Tracking"])


# ============================================================================
# Helper Functions
# ============================================================================

def get_tracking_service(db: AsyncSession = Depends(get_db)) -> TrackingService:
    """Dependency to get tracking service instance"""
    # TODO: Initialize Redis client here when implemented
    return TrackingService(db=db, redis_client=None)


def check_capability(
    capability: str,
    db: AsyncSession,
    current_user: User
):
    """Check if user has required capability"""
    cap_service = CapabilityService(db)
    has_cap = await cap_service.user_has_capability(current_user.id, capability)
    if not has_cap:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Missing required capability: {capability}"
        )


def get_driver_and_check_org(
    driver_id: UUID,
    current_user: User,
    db: AsyncSession
) -> Driver:
    """Get driver and verify organization access"""
    driver = await db.get(Driver, driver_id)
    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Driver {driver_id} not found"
        )

    if driver.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to driver from different organization"
        )

    return driver


# ============================================================================
# Location Tracking Endpoints
# ============================================================================

@router.post(
    "/locations",
    response_model=LocationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create single location record",
    description="Submit a single GPS location for the current driver. Use batch endpoint for multiple locations."
)
def create_location(
    location_data: LocationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Create a single location record (for urgent/real-time updates)"""
    # Check if current user is a driver
    if not current_user.driver_profile:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only drivers can submit location data"
        )

    driver = current_user.driver_profile

    try:
        location = await tracking_service.create_location(
            driver_id=driver.id,
            organization_id=current_user.organization_id,
            location_data=location_data
        )
        return LocationResponse.model_validate(location)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post(
    "/locations/batch",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Create multiple location records",
    description="Submit batch of GPS locations (5-50 records). More efficient than single location endpoint."
)
def create_locations_batch(
    batch_data: LocationBatchCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Create multiple location records in batch"""
    # Check if current user is a driver
    if not current_user.driver_profile:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only drivers can submit location data"
        )

    driver = current_user.driver_profile

    try:
        locations = await tracking_service.create_locations_batch(
            driver_id=driver.id,
            organization_id=current_user.organization_id,
            locations=batch_data.locations
        )
        return {
            "message": f"Successfully created {len(locations)} location records",
            "count": len(locations),
            "skipped": len(batch_data.locations) - len(locations)
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get(
    "/locations/live",
    response_model=List[LiveLocationResponse],
    summary="Get live locations for all drivers",
    description="Get latest location for each driver in organization. Cached for performance."
)
def get_live_locations(
    driver_ids: Optional[List[UUID]] = Query(None, description="Filter by specific driver IDs"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Get latest locations for all drivers (live tracking)"""
    await check_capability("tracking.view.live", db, current_user)

    locations = await tracking_service.get_latest_locations(
        organization_id=current_user.organization_id,
        driver_ids=driver_ids
    )
    return locations


@router.get(
    "/drivers/{driver_id}/location",
    response_model=LiveLocationResponse,
    summary="Get current location for specific driver",
    description="Get the most recent location for a single driver"
)
def get_driver_location(
    driver_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Get current location for a specific driver"""
    await check_capability("tracking.view.live", db, current_user)
    await get_driver_and_check_org(driver_id, current_user, db)

    locations = await tracking_service.get_latest_locations(
        organization_id=current_user.organization_id,
        driver_ids=[driver_id]
    )

    if not locations:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No location data found for driver"
        )

    return locations[0]


@router.get(
    "/drivers/{driver_id}/history",
    response_model=LocationListResponse,
    summary="Get location history for driver",
    description="Get historical location data with pagination and date range filtering"
)
def get_driver_history(
    driver_id: UUID,
    start_time: datetime = Query(..., description="Start of time range (ISO format)"),
    end_time: datetime = Query(..., description="End of time range (ISO format)"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(100, ge=1, le=500, description="Records per page"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Get location history for a driver within time range"""
    # Allow drivers to view their own history, or users with capability
    is_own_history = current_user.driver_profile and current_user.driver_profile.id == driver_id

    if not is_own_history:
        await check_capability("tracking.view.history", db, current_user)

    await get_driver_and_check_org(driver_id, current_user, db)

    locations, total = await tracking_service.get_driver_history(
        driver_id=driver_id,
        start_time=start_time,
        end_time=end_time,
        page=page,
        page_size=page_size
    )

    return LocationListResponse(
        locations=locations,
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total
    )


# ============================================================================
# Geofencing Endpoints
# ============================================================================

@router.get(
    "/geofences/events",
    response_model=GeofenceEventListResponse,
    summary="Get geofence events",
    description="Get history of geofence entry/exit events with filtering"
)
def get_geofence_events(
    driver_id: Optional[UUID] = Query(None, description="Filter by driver"),
    zone_id: Optional[UUID] = Query(None, description="Filter by zone"),
    start_time: Optional[datetime] = Query(None, description="Start time filter"),
    end_time: Optional[datetime] = Query(None, description="End time filter"),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Get geofence events with filtering"""
    await check_capability("tracking.view.geofences", db, current_user)

    events, total = await tracking_service.get_geofence_events(
        organization_id=current_user.organization_id,
        driver_id=driver_id,
        zone_id=zone_id,
        start_time=start_time,
        end_time=end_time,
        page=page,
        page_size=page_size
    )

    return GeofenceEventListResponse(
        events=events,
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total
    )


@router.post(
    "/geofences/events",
    response_model=GeofenceEventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Report geofence event",
    description="Create a geofence event when driver enters or exits a zone"
)
def create_geofence_event(
    event_data: GeofenceEventCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Report a geofence event (enter/exit)"""
    # Only drivers can report their own geofence events
    if not current_user.driver_profile:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only drivers can report geofence events"
        )

    driver = current_user.driver_profile

    event = await tracking_service.create_geofence_event(
        driver_id=driver.id,
        organization_id=current_user.organization_id,
        event_data=event_data
    )

    # Build response with related data
    zone = await db.get("Zone", event_data.zone_id)

    return GeofenceEventResponse(
        id=event.id,
        driver_id=event.driver_id,
        driver_name=driver.full_name,
        zone_id=event.zone_id,
        zone_name=zone.name if zone else "Unknown",
        organization_id=event.organization_id,
        event_type=event.event_type,
        latitude=float(event.latitude),
        longitude=float(event.longitude),
        timestamp=event.timestamp,
        created_at=event.created_at
    )


# ============================================================================
# Route Optimization Endpoints
# ============================================================================

@router.post(
    "/routes/optimize",
    response_model=RouteOptimizeResponse,
    summary="Optimize route",
    description="Optimize waypoint order using OSRM routing engine"
)
def optimize_route(
    request: RouteOptimizeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Optimize route waypoints using OSRM"""
    await check_capability("tracking.routes.optimize", db, current_user)

    try:
        result = await tracking_service.optimize_route_osrm(request.waypoints)
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get(
    "/routes",
    response_model=RouteListResponse,
    summary="List saved routes",
    description="Get list of saved routes for organization"
)
def list_routes(
    status_filter: Optional[str] = Query(None, description="Filter by status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List saved routes"""
    await check_capability("tracking.routes.view", db, current_user)

    from sqlalchemy import select, func, and_

    # Build filters
    filters = [RouteOptimization.organization_id == current_user.organization_id]
    if status_filter:
        filters.append(RouteOptimization.status == status_filter)

    # Count total
    count_query = select(func.count(RouteOptimization.id)).where(and_(*filters))
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # Get paginated data
    query = (
        select(RouteOptimization)
        .where(and_(*filters))
        .order_by(RouteOptimization.created_at.desc())
        .limit(page_size)
        .offset((page - 1) * page_size)
    )

    result = await db.execute(query)
    routes = result.scalars().all()

    return RouteListResponse(
        routes=[RouteResponse.model_validate(r) for r in routes],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total
    )


@router.post(
    "/routes",
    response_model=RouteResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create saved route",
    description="Save a route with waypoints"
)
def create_route(
    route_data: RouteCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a saved route"""
    await check_capability("tracking.routes.create", db, current_user)

    route = RouteOptimization(
        organization_id=current_user.organization_id,
        created_by=current_user.id,
        name=route_data.name,
        waypoints=[wp.dict() for wp in route_data.waypoints],
        optimized_route=[wp.dict() for wp in route_data.optimized_route] if route_data.optimized_route else None,
        total_distance=route_data.total_distance,
        estimated_duration=route_data.estimated_duration,
        status=route_data.status
    )

    db.add(route)
    await db.commit()
    await db.refresh(route)

    return RouteResponse.model_validate(route)


@router.get(
    "/routes/{route_id}",
    response_model=RouteResponse,
    summary="Get route details",
    description="Get details of a specific saved route"
)
def get_route(
    route_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get route details"""
    await check_capability("tracking.routes.view", db, current_user)

    route = await db.get(RouteOptimization, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found"
        )

    if route.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )

    return RouteResponse.model_validate(route)


@router.put(
    "/routes/{route_id}",
    response_model=RouteResponse,
    summary="Update route",
    description="Update a saved route"
)
def update_route(
    route_id: UUID,
    route_data: RouteUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update a route"""
    await check_capability("tracking.routes.update", db, current_user)

    route = await db.get(RouteOptimization, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found"
        )

    if route.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )

    # Update fields
    if route_data.name is not None:
        route.name = route_data.name
    if route_data.waypoints is not None:
        route.waypoints = [wp.dict() for wp in route_data.waypoints]
    if route_data.optimized_route is not None:
        route.optimized_route = [wp.dict() for wp in route_data.optimized_route]
    if route_data.total_distance is not None:
        route.total_distance = route_data.total_distance
    if route_data.estimated_duration is not None:
        route.estimated_duration = route_data.estimated_duration
    if route_data.status is not None:
        route.status = route_data.status

    await db.commit()
    await db.refresh(route)

    return RouteResponse.model_validate(route)


@router.delete(
    "/routes/{route_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete route",
    description="Delete a saved route"
)
def delete_route(
    route_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a route"""
    await check_capability("tracking.routes.delete", db, current_user)

    route = await db.get(RouteOptimization, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found"
        )

    if route.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )

    await db.delete(route)
    await db.commit()


# ============================================================================
# Admin Controls
# ============================================================================

@router.put(
    "/drivers/{driver_id}/tracking",
    response_model=DriverTrackingStatusResponse,
    summary="Enable/disable tracking for driver",
    description="Admin endpoint to control GPS tracking for a driver"
)
def update_driver_tracking(
    driver_id: UUID,
    tracking_update: DriverTrackingUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Enable or disable tracking for a driver"""
    await check_capability("tracking.admin.control", db, current_user)

    driver = await get_driver_and_check_org(driver_id, current_user, db)

    driver.tracking_enabled = tracking_update.tracking_enabled
    await db.commit()
    await db.refresh(driver)

    return DriverTrackingStatusResponse(
        driver_id=driver.id,
        driver_name=driver.full_name,
        tracking_enabled=driver.tracking_enabled,
        updated_at=driver.updated_at
    )


@router.get(
    "/drivers/{driver_id}/tracking",
    response_model=DriverTrackingStatusResponse,
    summary="Get tracking status for driver",
    description="Check if tracking is enabled for a driver"
)
def get_driver_tracking_status(
    driver_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get tracking status for a driver"""
    # Allow drivers to check their own status
    is_own_status = current_user.driver_profile and current_user.driver_profile.id == driver_id

    if not is_own_status:
        await check_capability("tracking.view.status", db, current_user)

    driver = await get_driver_and_check_org(driver_id, current_user, db)

    return DriverTrackingStatusResponse(
        driver_id=driver.id,
        driver_name=driver.full_name,
        tracking_enabled=driver.tracking_enabled,
        updated_at=driver.updated_at
    )


# ============================================================================
# Analytics
# ============================================================================

@router.get(
    "/analytics/summary",
    response_model=TrackingAnalyticsSummary,
    summary="Get trip analytics",
    description="Calculate analytics for a driver's trip (distance, speed, stops)"
)
def get_trip_analytics(
    driver_id: UUID = Query(..., description="Driver ID"),
    start_time: datetime = Query(..., description="Trip start time"),
    end_time: datetime = Query(..., description="Trip end time"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    tracking_service: TrackingService = Depends(get_tracking_service)
):
    """Get trip analytics summary"""
    await check_capability("tracking.view.analytics", db, current_user)
    await get_driver_and_check_org(driver_id, current_user, db)

    try:
        analytics = await tracking_service.calculate_trip_analytics(
            driver_id=driver_id,
            start_time=start_time,
            end_time=end_time
        )
        return analytics
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
