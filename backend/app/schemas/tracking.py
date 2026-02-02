"""
GPS Tracking Schemas
Pydantic models for GPS tracking API requests and responses
"""

from datetime import datetime
from typing import List, Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel, Field, validator, conlist


# ============================================================================
# Location Schemas
# ============================================================================

class LocationCreate(BaseModel):
    """Schema for creating a single location record"""
    latitude: float = Field(..., ge=-90, le=90, description="Latitude coordinate")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude coordinate")
    accuracy: Optional[float] = Field(None, ge=0, description="GPS accuracy in meters")
    altitude: Optional[float] = Field(None, description="Altitude in meters")
    speed: Optional[float] = Field(None, ge=0, description="Speed in meters/second")
    heading: Optional[float] = Field(None, ge=0, le=360, description="Heading in degrees")
    battery_level: Optional[int] = Field(None, ge=0, le=100, description="Device battery level (0-100)")
    is_mock_location: bool = Field(False, description="Whether location is from mock provider")
    timestamp: datetime = Field(..., description="GPS timestamp")

    class Config:
        json_schema_extra = {
            "example": {
                "latitude": 28.6139,
                "longitude": 77.2090,
                "accuracy": 10.5,
                "speed": 15.2,
                "heading": 90.0,
                "battery_level": 75,
                "is_mock_location": False,
                "timestamp": "2026-02-02T14:30:00Z"
            }
        }


class LocationBatchCreate(BaseModel):
    """Schema for batch creating location records"""
    locations: conlist(LocationCreate, min_length=1, max_length=50) = Field(
        ...,
        description="List of location records (max 50)"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "locations": [
                    {
                        "latitude": 28.6139,
                        "longitude": 77.2090,
                        "accuracy": 10.5,
                        "timestamp": "2026-02-02T14:30:00Z"
                    },
                    {
                        "latitude": 28.6145,
                        "longitude": 77.2095,
                        "accuracy": 12.0,
                        "timestamp": "2026-02-02T14:31:00Z"
                    }
                ]
            }
        }


class LocationResponse(BaseModel):
    """Schema for location response"""
    id: UUID
    driver_id: UUID
    organization_id: UUID
    latitude: float
    longitude: float
    accuracy: Optional[float]
    altitude: Optional[float]
    speed: Optional[float]
    heading: Optional[float]
    battery_level: Optional[int]
    is_mock_location: bool
    timestamp: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class LocationListResponse(BaseModel):
    """Schema for paginated location list response"""
    locations: List[LocationResponse]
    total: int
    page: int
    page_size: int
    has_next: bool

    class Config:
        json_schema_extra = {
            "example": {
                "locations": [],
                "total": 100,
                "page": 1,
                "page_size": 20,
                "has_next": True
            }
        }


class LiveLocationResponse(BaseModel):
    """Schema for live location with driver info"""
    driver_id: UUID
    driver_name: str
    latitude: float
    longitude: float
    speed: Optional[float]
    heading: Optional[float]
    battery_level: Optional[int]
    timestamp: datetime
    minutes_since_update: int
    is_moving: bool

    class Config:
        json_schema_extra = {
            "example": {
                "driver_id": "123e4567-e89b-12d3-a456-426614174000",
                "driver_name": "John Doe",
                "latitude": 28.6139,
                "longitude": 77.2090,
                "speed": 15.2,
                "heading": 90.0,
                "battery_level": 75,
                "timestamp": "2026-02-02T14:30:00Z",
                "minutes_since_update": 2,
                "is_moving": True
            }
        }


# ============================================================================
# Geofence Event Schemas
# ============================================================================

class GeofenceEventCreate(BaseModel):
    """Schema for creating a geofence event"""
    zone_id: UUID = Field(..., description="Zone ID")
    event_type: str = Field(..., description="Event type: 'enter' or 'exit'")
    latitude: float = Field(..., ge=-90, le=90, description="Latitude coordinate")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude coordinate")
    timestamp: datetime = Field(..., description="Event timestamp")
    location_id: Optional[UUID] = Field(None, description="Associated location record ID")

    @validator('event_type')
    def validate_event_type(cls, v):
        if v not in ['enter', 'exit']:
            raise ValueError("event_type must be 'enter' or 'exit'")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "zone_id": "123e4567-e89b-12d3-a456-426614174000",
                "event_type": "enter",
                "latitude": 28.6139,
                "longitude": 77.2090,
                "timestamp": "2026-02-02T14:30:00Z"
            }
        }


class GeofenceEventResponse(BaseModel):
    """Schema for geofence event response"""
    id: UUID
    driver_id: UUID
    driver_name: str
    zone_id: UUID
    zone_name: str
    organization_id: UUID
    event_type: str
    latitude: float
    longitude: float
    timestamp: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class GeofenceEventListResponse(BaseModel):
    """Schema for paginated geofence event list"""
    events: List[GeofenceEventResponse]
    total: int
    page: int
    page_size: int
    has_next: bool


# ============================================================================
# Route Optimization Schemas
# ============================================================================

class Waypoint(BaseModel):
    """Schema for a single waypoint"""
    lat: float = Field(..., ge=-90, le=90, description="Latitude")
    lng: float = Field(..., ge=-180, le=180, description="Longitude")
    address: Optional[str] = Field(None, description="Address or location name")
    order: Optional[int] = Field(None, description="Order in sequence")

    class Config:
        json_schema_extra = {
            "example": {
                "lat": 28.6139,
                "lng": 77.2090,
                "address": "Connaught Place, New Delhi",
                "order": 0
            }
        }


class RouteOptimizeRequest(BaseModel):
    """Schema for route optimization request"""
    waypoints: conlist(Waypoint, min_length=2, max_length=25) = Field(
        ...,
        description="List of waypoints to optimize (2-25)"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "waypoints": [
                    {"lat": 28.6139, "lng": 77.2090, "address": "Connaught Place"},
                    {"lat": 28.5355, "lng": 77.3910, "address": "Noida"},
                    {"lat": 28.4595, "lng": 77.0266, "address": "Gurgaon"}
                ]
            }
        }


class RouteOptimizeResponse(BaseModel):
    """Schema for route optimization response"""
    optimized_order: List[int] = Field(..., description="Optimized waypoint indices")
    optimized_waypoints: List[Waypoint] = Field(..., description="Waypoints in optimized order")
    total_distance: float = Field(..., description="Total distance in kilometers")
    estimated_duration: int = Field(..., description="Estimated duration in minutes")
    geometry: Optional[str] = Field(None, description="Encoded polyline geometry")

    class Config:
        json_schema_extra = {
            "example": {
                "optimized_order": [0, 2, 1],
                "optimized_waypoints": [],
                "total_distance": 45.6,
                "estimated_duration": 67,
                "geometry": "encoded_polyline_string"
            }
        }


class RouteCreate(BaseModel):
    """Schema for creating a saved route"""
    name: str = Field(..., min_length=1, max_length=255, description="Route name")
    waypoints: List[Waypoint] = Field(..., min_length=2, description="List of waypoints")
    optimized_route: Optional[List[Waypoint]] = Field(None, description="Optimized waypoints")
    total_distance: Optional[float] = Field(None, ge=0, description="Total distance in km")
    estimated_duration: Optional[int] = Field(None, ge=0, description="Duration in minutes")
    status: Optional[str] = Field('draft', description="Route status")

    @validator('status')
    def validate_status(cls, v):
        if v not in ['draft', 'active', 'completed']:
            raise ValueError("status must be 'draft', 'active', or 'completed'")
        return v


class RouteUpdate(BaseModel):
    """Schema for updating a route"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    waypoints: Optional[List[Waypoint]] = Field(None, min_length=2)
    optimized_route: Optional[List[Waypoint]] = None
    total_distance: Optional[float] = Field(None, ge=0)
    estimated_duration: Optional[int] = Field(None, ge=0)
    status: Optional[str] = None

    @validator('status')
    def validate_status(cls, v):
        if v is not None and v not in ['draft', 'active', 'completed']:
            raise ValueError("status must be 'draft', 'active', or 'completed'")
        return v


class RouteResponse(BaseModel):
    """Schema for route response"""
    id: UUID
    organization_id: UUID
    name: str
    waypoints: List[Dict[str, Any]]
    optimized_route: Optional[List[Dict[str, Any]]]
    total_distance: Optional[float]
    estimated_duration: Optional[int]
    created_by: Optional[UUID]
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class RouteListResponse(BaseModel):
    """Schema for paginated route list"""
    routes: List[RouteResponse]
    total: int
    page: int
    page_size: int
    has_next: bool


# ============================================================================
# Analytics Schemas
# ============================================================================

class TrackingAnalyticsSummary(BaseModel):
    """Schema for tracking analytics summary"""
    driver_id: UUID
    driver_name: str
    total_distance: float  # km
    total_duration: int  # minutes
    average_speed: float  # km/h
    stops_count: int
    start_time: datetime
    end_time: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "driver_id": "123e4567-e89b-12d3-a456-426614174000",
                "driver_name": "John Doe",
                "total_distance": 125.5,
                "total_duration": 180,
                "average_speed": 41.8,
                "stops_count": 5,
                "start_time": "2026-02-02T08:00:00Z",
                "end_time": "2026-02-02T11:00:00Z"
            }
        }


# ============================================================================
# Driver Tracking Control Schemas
# ============================================================================

class DriverTrackingUpdate(BaseModel):
    """Schema for enabling/disabling driver tracking"""
    tracking_enabled: bool = Field(..., description="Enable or disable tracking for driver")

    class Config:
        json_schema_extra = {
            "example": {
                "tracking_enabled": True
            }
        }


class DriverTrackingStatusResponse(BaseModel):
    """Schema for driver tracking status response"""
    driver_id: UUID
    driver_name: str
    tracking_enabled: bool
    updated_at: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "driver_id": "123e4567-e89b-12d3-a456-426614174000",
                "driver_name": "John Doe",
                "tracking_enabled": True,
                "updated_at": "2026-02-02T14:30:00Z"
            }
        }
