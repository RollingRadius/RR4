"""Make driver_locations.organization_id nullable

Revision ID: 091
Revises: 090
Create Date: 2026-08-31

A driver's company affiliation is not a fixed, permanent fact in this
domain: RR's own data model separately tracks vehicle ownership vs. who
currently hires/operates a vehicle (market_vehicles), and a vehicle's
crew (driver) assignment lives on the vehicle document itself with no
company-scoping check on RR's side — so the same driver can legitimately
appear on trips for genuinely different companies over time. A hard
NOT NULL organization_id on every GPS location row forced every trackable
driver to have one fixed "home" organization, which blocked self-registered
(org-less) drivers from ever submitting a location at all.

Confirmed via audit that organization_id here is not load-bearing for
access control or billing — the only two real consumers are
get_latest_locations()'s scoping filters and a geofence-zone lookup in
tracking_service.py, both belonging to the fleet-wide "live locations"
endpoint, which isn't wired to any real frontend UI yet (LiveTrackingScreen
still uses hardcoded mock markers). The per-trip Track feature already
resolves access via Trip.driver_id / Trip.organization_id instead
(GET /trips/{id}/vehicle-location), never reading this column at all.
"""

from alembic import op
import sqlalchemy as sa

revision = '091'
down_revision = '090'
branch_labels = None
depends_on = None


def upgrade():
    op.alter_column('driver_locations', 'organization_id', nullable=True)


def downgrade():
    op.alter_column('driver_locations', 'organization_id', nullable=False)
