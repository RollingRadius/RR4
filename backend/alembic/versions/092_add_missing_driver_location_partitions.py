"""add missing driver_locations partitions (Jun 2026 - Dec 2027)

Revision ID: 092_add_driver_location_partitions
Revises: 091_nullable_driver_location_org
Create Date: 2026-09-01 00:00:00.000000

driver_locations is RANGE-partitioned by month (see 010_add_gps_tracking.py),
but only Feb-May 2026 partitions were ever created. Every INSERT for a
timestamp outside that range has been failing with a CheckViolationError
("no partition of relation driver_locations found for row") since June 1,
2026 - silently breaking GPS tracking for every driver, not just this
feature's test driver. This backfills the missing months and adds a wide
buffer (through Dec 2027) so this doesn't quietly recur.
"""
from typing import Sequence, Union

from alembic import op

revision: str = '092'
down_revision: Union[str, None] = '091'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# (year, month) pairs to create partitions for: [start, end)
_MONTHS = [(2026, m) for m in range(6, 13)] + [(2027, m) for m in range(1, 13)]


def _bounds(year: int, month: int) -> tuple[str, str]:
    start = f"{year}-{month:02d}-01"
    if month == 12:
        end = f"{year + 1}-01-01"
    else:
        end = f"{year}-{month + 1:02d}-01"
    return start, end


def upgrade() -> None:
    for year, month in _MONTHS:
        start, end = _bounds(year, month)
        table_name = f"driver_locations_{year}_{month:02d}"
        op.execute(f"""
            CREATE TABLE IF NOT EXISTS {table_name} PARTITION OF driver_locations
                FOR VALUES FROM ('{start}') TO ('{end}')
        """)


def downgrade() -> None:
    for year, month in _MONTHS:
        table_name = f"driver_locations_{year}_{month:02d}"
        op.execute(f"DROP TABLE IF EXISTS {table_name}")
