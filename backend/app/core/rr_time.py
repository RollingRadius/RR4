"""RR's date-time format, one place (user 2026-11-24: tax declaration valid-till is a date AND time, like RR web).

RR keeps date-times in UTC as "%Y-%m-%dT%H:%M:%S" (no zone). RR web converts what its user picks in India time to UTC
before saving (rest-api.service.ts formateDate -> convertLocalGMTDateTimeIntoUTC) and shows it back in India time.
"""
from datetime import date, datetime, time, timezone
from typing import Optional

RR_FORMAT = "%Y-%m-%dT%H:%M:%S"


def to_rr(value) -> Optional[str]:
    """Our date-time (aware, or naive = UTC) -> RR's UTC string. A plain date (old rows) -> 00:00 UTC, as before."""
    if value is None:
        return None
    if isinstance(value, datetime):
        utc = value.astimezone(timezone.utc) if value.tzinfo else value
        return utc.strftime(RR_FORMAT)
    if isinstance(value, date):
        return datetime.combine(value, time(0, 0)).strftime(RR_FORMAT)
    return None


def from_rr(value) -> Optional[datetime]:
    """RR's value (UTC string / datetime) -> aware UTC datetime, or None."""
    if value in (None, ""):
        return None
    if isinstance(value, datetime):
        return value.astimezone(timezone.utc) if value.tzinfo else value.replace(tzinfo=timezone.utc)
    try:
        d = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None
    return d.astimezone(timezone.utc) if d.tzinfo else d.replace(tzinfo=timezone.utc)


def from_form(value: Optional[str]) -> Optional[datetime]:
    """The app's form value -> aware UTC datetime. ISO with a zone (new app: picked in India time, sent as UTC);
    a plain YYYY-MM-DD from an older app -> 00:00 UTC (what was sent to RR before). Raises ValueError."""
    s = (value or "").strip()
    if not s:
        return None
    if len(s) == 10:
        return datetime.combine(date.fromisoformat(s), time(0, 0), tzinfo=timezone.utc)
    return from_rr(datetime.fromisoformat(s.replace("Z", "+00:00")))
