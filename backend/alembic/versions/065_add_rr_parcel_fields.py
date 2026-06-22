"""Add RR parcel/consignor/consignee/vehicle fields to trips

Revision ID: 065
Revises: 064
Create Date: 2026-06-02

Adds all fields required to fully populate an RR parcel POST:
  - Consignor/consignee name & GSTIN
  - Pickup/unload address lines, PIN, no-entry-zone, depot_code
  - Parcel description, part_load flag
  - Vehicle: axle_type, number_of_wheels, expected_freight
"""

from alembic import op
import sqlalchemy as sa

revision = '065'
down_revision = '064'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Consignor / Consignee info
    op.add_column('trips', sa.Column('consignor_name',  sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('consignor_gstin', sa.String(20),  nullable=True))
    op.add_column('trips', sa.Column('consignee_name',  sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('consignee_gstin', sa.String(20),  nullable=True))

    # Pickup address
    op.add_column('trips', sa.Column('pickup_address_line1',  sa.String(200), nullable=True))
    op.add_column('trips', sa.Column('pickup_address_line2',  sa.String(200), nullable=True))
    op.add_column('trips', sa.Column('pickup_pin',            sa.String(10),  nullable=True))
    op.add_column('trips', sa.Column('pickup_no_entry_zone',  sa.Boolean,     nullable=True))

    # Unload address
    op.add_column('trips', sa.Column('unload_address_line1',  sa.String(200), nullable=True))
    op.add_column('trips', sa.Column('unload_address_line2',  sa.String(200), nullable=True))
    op.add_column('trips', sa.Column('unload_pin',            sa.String(10),  nullable=True))
    op.add_column('trips', sa.Column('unload_no_entry_zone',  sa.Boolean,     nullable=True))
    op.add_column('trips', sa.Column('depot_code',            sa.String(50),  nullable=True))

    # Parcel info
    op.add_column('trips', sa.Column('parcel_description', sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('part_load',          sa.Boolean,     nullable=True, server_default='false'))

    # Vehicle requirements
    op.add_column('trips', sa.Column('axle_type',        sa.String(20),   nullable=True))
    op.add_column('trips', sa.Column('number_of_wheels', sa.Integer,      nullable=True))
    op.add_column('trips', sa.Column('expected_freight', sa.Numeric(12,2), nullable=True))


def downgrade() -> None:
    for col in [
        'consignor_name', 'consignor_gstin', 'consignee_name', 'consignee_gstin',
        'pickup_address_line1', 'pickup_address_line2', 'pickup_pin', 'pickup_no_entry_zone',
        'unload_address_line1', 'unload_address_line2', 'unload_pin', 'unload_no_entry_zone',
        'depot_code', 'parcel_description', 'part_load',
        'axle_type', 'number_of_wheels', 'expected_freight',
    ]:
        op.drop_column('trips', col)
