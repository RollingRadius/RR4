"""rename fleet_owner to fleet_management and add fulfillment tracking fields

Changes:
  - roles.role_key: 'fleet_owner' → 'fleet_management'
  - roles.role_name: 'Fleet Owner' → 'Fleet Management'
  - organizations.business_type: 'fleet_owner' → 'fleet_management'
    (drops and recreates the check_business_type constraint)
  - load_requirements.fulfilling_org_id  — which fleet org accepted this load
  - trips.load_requirement_id            — which load requirement originated this trip

Revision ID: 026
Revises: 025
Create Date: 2026-03-23
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '026'
down_revision = '025'
branch_labels = None
depends_on = None

NEW_BUSINESS_TYPES = (
    'transportation', 'logistics', 'freight', 'courier',
    'delivery', 'taxi', 'rental', 'fleet_management', 'load_owner', 'other'
)
OLD_BUSINESS_TYPES = (
    'transportation', 'logistics', 'freight', 'courier',
    'delivery', 'taxi', 'rental', 'fleet_owner', 'load_owner', 'other'
)


def upgrade() -> None:
    # 1. Rename role: role_key + role_name + description
    op.execute(
        "UPDATE roles "
        "SET role_key = 'fleet_management', "
        "    role_name = 'Fleet Management', "
        "    description = 'Fleet management company with full access to fleet resources. "
        "Searches and fulfills load requirements posted by load owners.' "
        "WHERE role_key = 'fleet_owner'"
    )

    # 2. Drop old business_type check constraint
    op.drop_constraint('check_business_type', 'organizations', type_='check')

    # 3. Migrate existing fleet_owner organizations to fleet_management
    op.execute(
        "UPDATE organizations SET business_type = 'fleet_management' "
        "WHERE business_type = 'fleet_owner'"
    )

    # 4. Recreate constraint with fleet_management
    valid_list = ", ".join(f"'{t}'" for t in NEW_BUSINESS_TYPES)
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({valid_list})"
    )

    # 5. Add fulfilling_org_id to load_requirements
    op.add_column(
        'load_requirements',
        sa.Column(
            'fulfilling_org_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('organizations.id', ondelete='SET NULL'),
            nullable=True,
        )
    )
    op.create_index(
        'ix_load_requirements_fulfilling_org_id',
        'load_requirements',
        ['fulfilling_org_id'],
    )

    # 6. Add load_requirement_id to trips
    op.add_column(
        'trips',
        sa.Column(
            'load_requirement_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('load_requirements.id', ondelete='SET NULL'),
            nullable=True,
        )
    )
    op.create_index(
        'ix_trips_load_requirement_id',
        'trips',
        ['load_requirement_id'],
    )


def downgrade() -> None:
    op.drop_index('ix_trips_load_requirement_id', table_name='trips')
    op.drop_column('trips', 'load_requirement_id')

    op.drop_index('ix_load_requirements_fulfilling_org_id', table_name='load_requirements')
    op.drop_column('load_requirements', 'fulfilling_org_id')

    # Restore business_type constraint with fleet_owner
    op.drop_constraint('check_business_type', 'organizations', type_='check')
    op.execute(
        "UPDATE organizations SET business_type = 'fleet_owner' "
        "WHERE business_type = 'fleet_management'"
    )
    valid_list = ", ".join(f"'{t}'" for t in OLD_BUSINESS_TYPES)
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({valid_list})"
    )

    # Restore role_key
    op.execute(
        "UPDATE roles "
        "SET role_key = 'fleet_owner', "
        "    role_name = 'Fleet Owner', "
        "    description = 'Fleet company owner with full access to fleet management resources.' "
        "WHERE role_key = 'fleet_management'"
    )
