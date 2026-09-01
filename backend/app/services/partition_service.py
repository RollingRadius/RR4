"""Ensures driver_locations has a partition for the current and next month.

driver_locations is RANGE-partitioned by month (see migration 010). If the
partition for "now" is ever missing, every GPS insert fails with a
CheckViolationError and location tracking silently breaks for every driver
(this happened for real: partitions were created once through May 2026 and
never extended, so tracking was broken from June 2026 until this was found
and backfilled in migration 092). This runs on every app startup as a cheap,
idempotent safety net so a missing month is caught immediately instead of
months later.
"""
import logging
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


def _month_bounds(year: int, month: int) -> tuple[str, str]:
    start = f"{year}-{month:02d}-01"
    if month == 12:
        end = f"{year + 1}-01-01"
    else:
        end = f"{year}-{month + 1:02d}-01"
    return start, end


def ensure_driver_location_partitions(db: Session, months_ahead: int = 3) -> None:
    now = datetime.now(timezone.utc)
    year, month = now.year, now.month
    for _ in range(months_ahead + 1):
        start, end = _month_bounds(year, month)
        table_name = f"driver_locations_{year}_{month:02d}"
        try:
            db.execute(text(f"""
                CREATE TABLE IF NOT EXISTS {table_name} PARTITION OF driver_locations
                    FOR VALUES FROM ('{start}') TO ('{end}')
            """))
            db.commit()
        except Exception:
            db.rollback()
            logger.exception(f"Failed to ensure driver_locations partition {table_name}")
        month += 1
        if month > 12:
            month = 1
            year += 1
