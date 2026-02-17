"""
Branding Schemas
Pydantic models for organization branding endpoints
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, Dict, Any
from datetime import datetime
import re


def validate_hex_color(color: str) -> str:
    """Validate and normalize hex color format (#RRGGBB)"""
    if not color:
        raise ValueError("Color cannot be empty")

    # Remove whitespace
    color = color.strip()

    # Check format
    hex_pattern = r'^#[0-9A-Fa-f]{6}$'
    if not re.match(hex_pattern, color):
        raise ValueError(f"Invalid hex color format: {color}. Must be #RRGGBB (e.g., #1E40AF)")

    # Normalize to uppercase
    return color.upper()


class BrandingColors(BaseModel):
    """Color configuration for organization branding"""
    primary_color: str = Field(default='#1E40AF', description="Primary brand color")
    primary_dark: str = Field(default='#1E3A8A', description="Dark variant of primary color")
    primary_light: str = Field(default='#3B82F6', description="Light variant of primary color")
    secondary_color: str = Field(default='#06B6D4', description="Secondary brand color")
    accent_color: str = Field(default='#0EA5E9', description="Accent color for highlights")
    background_primary: str = Field(default='#F8FAFC', description="Primary background color")
    background_secondary: str = Field(default='#FFFFFF', description="Secondary background color")

    @field_validator(
        'primary_color',
        'primary_dark',
        'primary_light',
        'secondary_color',
        'accent_color',
        'background_primary',
        'background_secondary'
    )
    @classmethod
    def validate_color_format(cls, v):
        return validate_hex_color(v)


class LogoInfo(BaseModel):
    """Logo information"""
    url: Optional[str] = None
    filename: Optional[str] = None
    size_bytes: Optional[int] = None
    uploaded_at: Optional[datetime] = None


class BrandingUpdateRequest(BaseModel):
    """Request to update organization branding"""
    colors: Optional[BrandingColors] = None
    theme_config: Optional[Dict[str, Any]] = Field(default=None, description="Additional theme configuration")


class BrandingResponse(BaseModel):
    """Organization branding response"""
    id: str
    organization_id: str
    logo: Optional[LogoInfo] = None
    colors: BrandingColors
    theme_config: Dict[str, Any] = {}
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class LogoUploadResponse(BaseModel):
    """Logo upload response"""
    success: bool
    message: str
    logo_url: Optional[str] = None
    filename: Optional[str] = None
    size_bytes: Optional[int] = None
