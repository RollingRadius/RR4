"""
GPS Tracking Service
Business logic for location tracking, geofencing, and route optimization
"""

from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any, Tuple
from uuid import UUID
import json
import logging

from sqlalchemy import select, and_, desc, func
from sqlalchemy.ext.asyncio import AsyncSession
from shapely.geometry import Point, Polygon
from geopy.distance import geodesic
import polyline
import requests
import redis.asyncio as redis

from app.models.tracking import DriverLocation, GeofenceEvent, RouteOptimization
from app.models.driver import Driver
from app.models.zone import Zone
from app.schemas.tracking import (
    LocationCreate,
    LocationResponse,
    LiveLocationResponse,
    GeofenceEventCreate,
    GeofenceEventResponse,
    RouteOptimizeRequest,
    RouteOptimizeResponse,
    Waypoint,
    TrackingAnalyticsSummary
)
from app.config import settings

logger = logging.getLogger(__name__)


class TrackingService:
    """Service for GPS tracking operations"""

    def __init__(self, db: AsyncSession, redis_client: Optional[redis.Redis] = None):
        self.db = db
        self.redis = redis_client
        self.osrm_base_url = getattr(settings, 'OSRM_BASE_URL', 'http://localhost:5000')

    # ========================================================================
    # Location Management
    # ========================================================================

    async def create_location(
        self,
        driver_id: UUID,
        organization_id: UUID,
        location_data: LocationCreate
    ) -> DriverLocation:
        """
        Create a single location record for a driver.

        Args:
            driver_id: Driver UUID
            organization_id: Organization UUID
            location_data: Location data from request

        Returns:
            Created DriverLocation instance

        Raises:
            ValueError: If tracking is not enabled for driver or location is invalid
        """
        # Verify tracking is enabled
        driver = await self.db.get(Driver, driver_id)
        if not driver:
            raise ValueError(f"Driver {driver_id} not found")
        if not driver.tracking_enabled:
            raise ValueError(f"Tracking not enabled for driver {driver_id}")

        # Validate location accuracy (reject if too inaccurate)
        if location_data.accuracy and location_data.accuracy > 100:
            logger.warning(f"Rejecting location for driver {driver_id}: accuracy {location_data.accuracy}m")
            raise ValueError("Location accuracy too low (>100m)")

        # Create location record
        location = DriverLocation(
            driver_id=driver_id,
            organization_id=organization_id,
            latitude=location_data.latitude,
            longitude=location_data.longitude,
            accuracy=location_data.accuracy,
            altitude=location_data.altitude,
            speed=location_data.speed,
            heading=location_data.heading,
            battery_level=location_data.battery_level,
            is_mock_location=location_data.is_mock_location,
            timestamp=location_data.timestamp
        )

        self.db.add(location)
        await self.db.commit()
        await self.db.refresh(location)

        # Update Redis cache with latest location
        await self._cache_latest_location(location)

        # Check for geofence events
        await self._check_geofences(location)

        return location

    async def create_locations_batch(
        self,
        driver_id: UUID,
        organization_id: UUID,
        locations: List[LocationCreate]
    ) -> List[DriverLocation]:
        """
        Create multiple location records in batch.

        Args:
            driver_id: Driver UUID
            organization_id: Organization UUID
            locations: List of location data

        Returns:
            List of created DriverLocation instances
        """
        # Verify tracking is enabled
        driver = await self.db.get(Driver, driver_id)
        if not driver:
            raise ValueError(f"Driver {driver_id} not found")
        if not driver.tracking_enabled:
            raise ValueError(f"Tracking not enabled for driver {driver_id}")

        # Create location records
        location_records = []
        for loc_data in locations:
            # Skip locations with poor accuracy
            if loc_data.accuracy and loc_data.accuracy > 100:
                logger.warning(f"Skipping location: accuracy {loc_data.accuracy}m")
                continue

            location = DriverLocation(
                driver_id=driver_id,
                organization_id=organization_id,
                latitude=loc_data.latitude,
                longitude=loc_data.longitude,
                accuracy=loc_data.accuracy,
                altitude=loc_data.altitude,
                speed=loc_data.speed,
                heading=loc_data.heading,
                battery_level=loc_data.battery_level,
                is_mock_location=loc_data.is_mock_location,
                timestamp=loc_data.timestamp
            )
            location_records.append(location)

        # Bulk insert
        self.db.add_all(location_records)
        await self.db.commit()

        # Cache the latest location (most recent timestamp)
        if location_records:
            latest = max(location_records, key=lambda x: x.timestamp)
            await self._cache_latest_location(latest)

            # Check geofences for latest location only (to avoid spam)
            await self._check_geofences(latest)

        return location_records

    async def get_latest_locations(
        self,
        organization_id: UUID,
        driver_ids: Optional[List[UUID]] = None
    ) -> List[LiveLocationResponse]:
        """
        Get latest location for each driver (with Redis caching).

        Args:
            organization_id: Organization UUID
            driver_ids: Optional list of specific driver IDs to filter

        Returns:
            List of LiveLocationResponse with driver info
        """
        # Try Redis cache first
        cached_locations = await self._get_cached_locations(organization_id, driver_ids)
        if cached_locations:
            return cached_locations

        # Fallback to database query
        # Get latest location per driver using window function
        subquery = (
            select(
                DriverLocation.driver_id,
                func.max(DriverLocation.timestamp).label('max_timestamp')
            )
            .where(DriverLocation.organization_id == organization_id)
        )

        if driver_ids:
            subquery = subquery.where(DriverLocation.driver_id.in_(driver_ids))

        subquery = subquery.group_by(DriverLocation.driver_id).subquery()

        # Join to get full location details
        query = (
            select(DriverLocation, Driver)
            .join(
                subquery,
                and_(
                    DriverLocation.driver_id == subquery.c.driver_id,
                    DriverLocation.timestamp == subquery.c.max_timestamp
                )
            )
            .join(Driver, DriverLocation.driver_id == Driver.id)
            .where(DriverLocation.organization_id == organization_id)
        )

        result = await self.db.execute(query)
        rows = result.all()

        # Build response
        now = datetime.utcnow()
        live_locations = []
        for location, driver in rows:
            minutes_since = int((now - location.timestamp.replace(tzinfo=None)).total_seconds() / 60)
            is_moving = location.speed is not None and location.speed > 0.5  # >0.5 m/s

            live_locations.append(LiveLocationResponse(
                driver_id=driver.id,
                driver_name=driver.full_name,
                latitude=float(location.latitude),
                longitude=float(location.longitude),
                speed=location.speed,
                heading=location.heading,
                battery_level=location.battery_level,
                timestamp=location.timestamp,
                minutes_since_update=minutes_since,
                is_moving=is_moving
            ))

        # Cache results in Redis
        await self._cache_live_locations(organization_id, live_locations)

        return live_locations

    async def get_driver_history(
        self,
        driver_id: UUID,
        start_time: datetime,
        end_time: datetime,
        page: int = 1,
        page_size: int = 100
    ) -> Tuple[List[LocationResponse], int]:
        """
        Get location history for a driver within time range.

        Args:
            driver_id: Driver UUID
            start_time: Start of time range
            end_time: End of time range
            page: Page number (1-indexed)
            page_size: Number of records per page

        Returns:
            Tuple of (location list, total count)
        """
        # Count total
        count_query = (
            select(func.count(DriverLocation.id))
            .where(
                and_(
                    DriverLocation.driver_id == driver_id,
                    DriverLocation.timestamp >= start_time,
                    DriverLocation.timestamp <= end_time
                )
            )
        )
        total_result = await self.db.execute(count_query)
        total = total_result.scalar() or 0

        # Get paginated data
        query = (
            select(DriverLocation)
            .where(
                and_(
                    DriverLocation.driver_id == driver_id,
                    DriverLocation.timestamp >= start_time,
                    DriverLocation.timestamp <= end_time
                )
            )
            .order_by(desc(DriverLocation.timestamp))
            .limit(page_size)
            .offset((page - 1) * page_size)
        )

        result = await self.db.execute(query)
        locations = result.scalars().all()

        location_responses = [
            LocationResponse.model_validate(loc) for loc in locations
        ]

        return location_responses, total

    # ========================================================================
    # Geofencing
    # ========================================================================

    async def detect_geofence_events(
        self,
        location: DriverLocation,
        zones: List[Zone]
    ) -> List[str]:
        """
        Detect if location is inside any geofence zones.

        Args:
            location: DriverLocation instance
            zones: List of Zone instances to check

        Returns:
            List of zone IDs that contain the location
        """
        point = Point(float(location.longitude), float(location.latitude))
        matching_zones = []

        for zone in zones:
            # Parse zone coordinates (assuming JSONB format: [[lng, lat], ...])
            if not zone.coordinates:
                continue

            try:
                coords = json.loads(zone.coordinates) if isinstance(zone.coordinates, str) else zone.coordinates
                polygon = Polygon(coords)

                if polygon.contains(point):
                    matching_zones.append(str(zone.id))
            except Exception as e:
                logger.error(f"Error checking zone {zone.id}: {e}")

        return matching_zones

    async def create_geofence_event(
        self,
        driver_id: UUID,
        organization_id: UUID,
        event_data: GeofenceEventCreate
    ) -> GeofenceEvent:
        """
        Create a geofence event (enter/exit).

        Args:
            driver_id: Driver UUID
            organization_id: Organization UUID
            event_data: Event data from request

        Returns:
            Created GeofenceEvent instance
        """
        event = GeofenceEvent(
            driver_id=driver_id,
            zone_id=event_data.zone_id,
            organization_id=organization_id,
            event_type=event_data.event_type,
            location_id=event_data.location_id,
            latitude=event_data.latitude,
            longitude=event_data.longitude,
            timestamp=event_data.timestamp
        )

        self.db.add(event)
        await self.db.commit()
        await self.db.refresh(event)

        return event

    async def get_geofence_events(
        self,
        organization_id: UUID,
        driver_id: Optional[UUID] = None,
        zone_id: Optional[UUID] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        page: int = 1,
        page_size: int = 50
    ) -> Tuple[List[GeofenceEventResponse], int]:
        """
        Get geofence events with filtering.

        Args:
            organization_id: Organization UUID
            driver_id: Optional driver filter
            zone_id: Optional zone filter
            start_time: Optional start time filter
            end_time: Optional end time filter
            page: Page number
            page_size: Records per page

        Returns:
            Tuple of (event list, total count)
        """
        # Build filters
        filters = [GeofenceEvent.organization_id == organization_id]
        if driver_id:
            filters.append(GeofenceEvent.driver_id == driver_id)
        if zone_id:
            filters.append(GeofenceEvent.zone_id == zone_id)
        if start_time:
            filters.append(GeofenceEvent.timestamp >= start_time)
        if end_time:
            filters.append(GeofenceEvent.timestamp <= end_time)

        # Count total
        count_query = select(func.count(GeofenceEvent.id)).where(and_(*filters))
        total_result = await self.db.execute(count_query)
        total = total_result.scalar() or 0

        # Get paginated data with joins
        query = (
            select(GeofenceEvent, Driver, Zone)
            .join(Driver, GeofenceEvent.driver_id == Driver.id)
            .join(Zone, GeofenceEvent.zone_id == Zone.id)
            .where(and_(*filters))
            .order_by(desc(GeofenceEvent.timestamp))
            .limit(page_size)
            .offset((page - 1) * page_size)
        )

        result = await self.db.execute(query)
        rows = result.all()

        # Build response
        events = []
        for event, driver, zone in rows:
            events.append(GeofenceEventResponse(
                id=event.id,
                driver_id=event.driver_id,
                driver_name=driver.full_name,
                zone_id=event.zone_id,
                zone_name=zone.name,
                organization_id=event.organization_id,
                event_type=event.event_type,
                latitude=float(event.latitude),
                longitude=float(event.longitude),
                timestamp=event.timestamp,
                created_at=event.created_at
            ))

        return events, total

    # ========================================================================
    # Route Optimization
    # ========================================================================

    async def optimize_route_osrm(
        self,
        waypoints: List[Waypoint]
    ) -> RouteOptimizeResponse:
        """
        Optimize route using OSRM server.

        Args:
            waypoints: List of waypoints to optimize

        Returns:
            RouteOptimizeResponse with optimized order and metrics

        Raises:
            ValueError: If OSRM request fails
        """
        if len(waypoints) < 2:
            raise ValueError("At least 2 waypoints required")

        # Build OSRM coordinates string (lng,lat;lng,lat;...)
        coords = ";".join([f"{wp.lng},{wp.lat}" for wp in waypoints])

        # Use OSRM trip service for route optimization
        url = f"{self.osrm_base_url}/trip/v1/driving/{coords}"
        params = {
            'source': 'first',  # Start from first waypoint
            'roundtrip': 'false',  # Not a round trip
            'geometries': 'polyline'
        }

        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()

            if data.get('code') != 'Ok':
                raise ValueError(f"OSRM error: {data.get('message', 'Unknown error')}")

            # Parse OSRM response
            trip = data['trips'][0]
            waypoint_indices = [wp['waypoint_index'] for wp in data['waypoints']]

            # Build optimized waypoints in order
            optimized_waypoints = [waypoints[i] for i in waypoint_indices]
            for idx, wp in enumerate(optimized_waypoints):
                wp.order = idx

            return RouteOptimizeResponse(
                optimized_order=waypoint_indices,
                optimized_waypoints=optimized_waypoints,
                total_distance=round(trip['distance'] / 1000, 2),  # meters to km
                estimated_duration=round(trip['duration'] / 60),  # seconds to minutes
                geometry=trip.get('geometry')
            )

        except requests.RequestException as e:
            logger.error(f"OSRM request failed: {e}")
            raise ValueError(f"Route optimization failed: {str(e)}")

    # ========================================================================
    # Analytics
    # ========================================================================

    async def calculate_trip_analytics(
        self,
        driver_id: UUID,
        start_time: datetime,
        end_time: datetime
    ) -> TrackingAnalyticsSummary:
        """
        Calculate analytics for a driver's trip.

        Args:
            driver_id: Driver UUID
            start_time: Trip start time
            end_time: Trip end time

        Returns:
            TrackingAnalyticsSummary with metrics
        """
        # Get all locations in time range
        query = (
            select(DriverLocation, Driver)
            .join(Driver, DriverLocation.driver_id == Driver.id)
            .where(
                and_(
                    DriverLocation.driver_id == driver_id,
                    DriverLocation.timestamp >= start_time,
                    DriverLocation.timestamp <= end_time
                )
            )
            .order_by(DriverLocation.timestamp)
        )

        result = await self.db.execute(query)
        rows = result.all()

        if not rows:
            raise ValueError("No location data found for the specified time range")

        locations = [row[0] for row in rows]
        driver = rows[0][1]

        # Calculate distance
        total_distance = 0.0
        stops_count = 0
        prev_loc = None

        for loc in locations:
            if prev_loc:
                # Calculate distance using geodesic
                dist = geodesic(
                    (float(prev_loc.latitude), float(prev_loc.longitude)),
                    (float(loc.latitude), float(loc.longitude))
                ).kilometers
                total_distance += dist

                # Detect stops (speed < 0.5 m/s for >5 minutes)
                if loc.speed and loc.speed < 0.5:
                    time_diff = (loc.timestamp - prev_loc.timestamp).total_seconds()
                    if time_diff > 300:  # 5 minutes
                        stops_count += 1

            prev_loc = loc

        # Calculate duration and average speed
        duration_minutes = int((end_time - start_time).total_seconds() / 60)
        avg_speed = (total_distance / duration_minutes * 60) if duration_minutes > 0 else 0.0

        return TrackingAnalyticsSummary(
            driver_id=driver_id,
            driver_name=driver.full_name,
            total_distance=round(total_distance, 2),
            total_duration=duration_minutes,
            average_speed=round(avg_speed, 2),
            stops_count=stops_count,
            start_time=start_time,
            end_time=end_time
        )

    # ========================================================================
    # Private Helper Methods
    # ========================================================================

    async def _cache_latest_location(self, location: DriverLocation):
        """Cache latest location in Redis"""
        if not self.redis:
            return

        key = f"tracking:live:{location.organization_id}:{location.driver_id}"
        value = json.dumps({
            'lat': float(location.latitude),
            'lng': float(location.longitude),
            'speed': location.speed,
            'heading': location.heading,
            'battery_level': location.battery_level,
            'timestamp': location.timestamp.isoformat()
        })

        try:
            await self.redis.setex(key, 300, value)  # 5-minute TTL
        except Exception as e:
            logger.error(f"Redis cache error: {e}")

    async def _get_cached_locations(
        self,
        organization_id: UUID,
        driver_ids: Optional[List[UUID]] = None
    ) -> Optional[List[LiveLocationResponse]]:
        """Get cached locations from Redis"""
        if not self.redis:
            return None

        # For now, skip cache if filtering by specific drivers
        # (would need to fetch each driver individually)
        if driver_ids:
            return None

        # Try to get cached data
        # TODO: Implement efficient Redis scan for org locations
        return None

    async def _cache_live_locations(
        self,
        organization_id: UUID,
        locations: List[LiveLocationResponse]
    ):
        """Cache live locations in Redis"""
        if not self.redis:
            return

        # Cache individual driver locations
        for loc in locations:
            key = f"tracking:live:{organization_id}:{loc.driver_id}"
            value = json.dumps({
                'lat': loc.latitude,
                'lng': loc.longitude,
                'speed': loc.speed,
                'heading': loc.heading,
                'battery_level': loc.battery_level,
                'timestamp': loc.timestamp.isoformat()
            })

            try:
                await self.redis.setex(key, 300, value)
            except Exception as e:
                logger.error(f"Redis cache error: {e}")

    async def _check_geofences(self, location: DriverLocation):
        """Check if location triggers any geofence events"""
        # Get active zones for organization
        query = select(Zone).where(
            and_(
                Zone.organization_id == location.organization_id,
                Zone.is_active == True
            )
        )
        result = await self.db.execute(query)
        zones = result.scalars().all()

        if not zones:
            return

        # Detect which zones contain the location
        matching_zone_ids = await self.detect_geofence_events(location, zones)

        # TODO: Implement enter/exit detection by comparing with previous location
        # For now, just log detected zones
        if matching_zone_ids:
            logger.info(f"Driver {location.driver_id} in zones: {matching_zone_ids}")
