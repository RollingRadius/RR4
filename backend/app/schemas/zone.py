"""
Zone Schemas
Pydantic models for zone/polygon endpoints
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime


class CoordinatePoint(BaseModel):
    """Single coordinate point [latitude, longitude]"""
    latitude: float = Field(..., ge=-90, le=90, description="Latitude (-90 to 90)")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude (-180 to 180)")

    def to_list(self) -> List[float]:
        """Convert to [lat, lng] list"""
        return [self.latitude, self.longitude]


class PolygonCoordinates(BaseModel):
    """Polygon coordinates structure"""
    type: str = Field(default="Polygon", description="Geometry type")
    coordinates: List[List[float]] = Field(..., min_length=3, description="Array of [lat, lng] points")

    @field_validator('type')
    @classmethod
    def validate_type(cls, v):
        if v != "Polygon":
            raise ValueError('Type must be "Polygon"')
        return v

    @field_validator('coordinates')
    @classmethod
    def validate_coordinates(cls, v):
        if len(v) < 3:
            raise ValueError('Polygon must have at least 3 coordinate points')

        for coord in v:
            if len(coord) != 2:
                raise ValueError('Each coordinate must be [latitude, longitude]')

            lat, lng = coord
            if not (-90 <= lat <= 90):
                raise ValueError(f'Invalid latitude: {lat}. Must be between -90 and 90')
            if not (-180 <= lng <= 180):
                raise ValueError(f'Invalid longitude: {lng}. Must be between -180 and 180')

        return v


class ZoneCreateRequest(BaseModel):
    """Create new zone request"""
    name: str = Field(..., min_length=1, max_length=255, description="Zone name")
    zone_type: str = Field(..., description="Zone type")
    description: Optional[str] = Field(None, max_length=1000, description="Zone description")
    coordinates: PolygonCoordinates = Field(..., description="Polygon coordinates")
    color: str = Field(default='#3B82F6', description="Hex color code")
    fill_opacity: str = Field(default='0.3', description="Fill opacity (0.0 to 1.0)")
    stroke_width: str = Field(default='2', description="Border width in pixels")

    @field_validator('zone_type')
    @classmethod
    def validate_zone_type(cls, v):
        valid_types = ['service_area', 'parking', 'restricted', 'delivery', 'geofence', 'custom']
        if v not in valid_types:
            raise ValueError(f'Zone type must be one of: {", ".join(valid_types)}')
        return v

    @field_validator('color')
    @classmethod
    def validate_color(cls, v):
        import re
        if not re.match(r'^#[0-9A-Fa-f]{6}$', v):
            raise ValueError('Color must be a valid hex code (e.g., #3B82F6)')
        return v

    @field_validator('fill_opacity')
    @classmethod
    def validate_opacity(cls, v):
        try:
            opacity = float(v)
            if not (0.0 <= opacity <= 1.0):
                raise ValueError('Opacity must be between 0.0 and 1.0')
        except ValueError:
            raise ValueError('Opacity must be a number between 0.0 and 1.0')
        return v

    @field_validator('stroke_width')
    @classmethod
    def validate_stroke_width(cls, v):
        try:
            width = float(v)
            if width < 0:
                raise ValueError('Stroke width must be positive')
        except ValueError:
            raise ValueError('Stroke width must be a positive number')
        return v


class ZoneUpdateRequest(BaseModel):
    """Update zone request (all fields optional)"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    zone_type: Optional[str] = None
    description: Optional[str] = Field(None, max_length=1000)
    coordinates: Optional[PolygonCoordinates] = None
    color: Optional[str] = None
    fill_opacity: Optional[str] = None
    stroke_width: Optional[str] = None
    status: Optional[str] = None

    @field_validator('zone_type')
    @classmethod
    def validate_zone_type(cls, v):
        if v:
            valid_types = ['service_area', 'parking', 'restricted', 'delivery', 'geofence', 'custom']
            if v not in valid_types:
                raise ValueError(f'Zone type must be one of: {", ".join(valid_types)}')
        return v

    @field_validator('color')
    @classmethod
    def validate_color(cls, v):
        if v:
            import re
            if not re.match(r'^#[0-9A-Fa-f]{6}$', v):
                raise ValueError('Color must be a valid hex code (e.g., #3B82F6)')
        return v

    @field_validator('status')
    @classmethod
    def validate_status(cls, v):
        if v:
            valid_statuses = ['active', 'inactive', 'archived']
            if v not in valid_statuses:
                raise ValueError(f'Status must be one of: {", ".join(valid_statuses)}')
        return v


class ZoneResponse(BaseModel):
    """Zone details response"""
    zone_id: str
    organization_id: str
    name: str
    zone_type: str
    description: Optional[str]
    coordinates: dict  # The JSONB polygon structure
    color: str
    fill_opacity: str
    stroke_width: str
    status: str
    coordinate_count: int  # Number of points in polygon
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ZoneListResponse(BaseModel):
    """Paginated zone list response"""
    success: bool
    zones: List[ZoneResponse]
    total: int
    skip: int
    limit: int


class ZoneGeoJSONResponse(BaseModel):
    """Zone in GeoJSON format"""
    type: str = "Feature"
    id: str
    properties: dict
    geometry: dict
