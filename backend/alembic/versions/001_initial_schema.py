"""Initial schema with all tables

Revision ID: 001_initial_schema
Revises:
Create Date: 2024-01-21

Creates all 9 tables:
1. users
2. organizations
3. roles
4. user_organizations
5. security_questions
6. user_security_answers
7. verification_tokens
8. recovery_attempts
9. audit_logs
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create all tables and insert initial data"""

    # 1. Create users table
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('full_name', sa.String(length=255), nullable=False),
        sa.Column('username', sa.String(length=50), nullable=False, unique=True),
        sa.Column('email', sa.String(length=255), nullable=True, unique=True),
        sa.Column('phone', sa.String(length=20), nullable=False),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('auth_method', sa.String(length=20), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='pending_verification'),
        sa.Column('email_verified', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('failed_login_attempts', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('locked_until', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('last_login', sa.DateTime(), nullable=True),
        sa.CheckConstraint("auth_method IN ('email', 'security_questions')", name='check_auth_method'),
        sa.CheckConstraint(
            "(auth_method = 'email' AND email IS NOT NULL) OR (auth_method = 'security_questions')",
            name='check_email_if_email_auth'
        )
    )
    op.create_index('idx_users_username', 'users', ['username'])
    op.create_index('idx_users_email', 'users', ['email'], postgresql_where=sa.text('email IS NOT NULL'))
    op.create_index('idx_users_status', 'users', ['status'])

    # 2. Create organizations table
    op.create_table(
        'organizations',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('company_name', sa.String(length=255), nullable=False),
        sa.Column('business_type', sa.String(length=50), nullable=False),
        sa.Column('gstin', sa.String(length=15), nullable=True, unique=True),
        sa.Column('pan_number', sa.String(length=10), nullable=True),
        sa.Column('registration_number', sa.String(length=100), nullable=True),
        sa.Column('registration_date', sa.Date(), nullable=True),
        sa.Column('business_email', sa.String(length=255), nullable=False),
        sa.Column('business_phone', sa.String(length=20), nullable=False),
        sa.Column('address', sa.Text(), nullable=False),
        sa.Column('city', sa.String(length=100), nullable=False),
        sa.Column('state', sa.String(length=100), nullable=False),
        sa.Column('pincode', sa.String(length=10), nullable=False),
        sa.Column('country', sa.String(length=100), nullable=False, server_default='India'),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.CheckConstraint(
            "gstin IS NULL OR gstin ~ '^\\d{2}[A-Z]{5}\\d{4}[A-Z]{1}[A-Z\\d]{1}[Z]{1}[A-Z\\d]{1}$'",
            name='check_gstin_format'
        ),
        sa.CheckConstraint(
            "pan_number IS NULL OR pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'",
            name='check_pan_format'
        )
    )
    op.create_index('idx_organizations_name', 'organizations', ['company_name'])
    op.create_index('idx_organizations_gstin', 'organizations', ['gstin'], postgresql_where=sa.text('gstin IS NOT NULL'))

    # 3. Create roles table
    op.create_table(
        'roles',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('role_name', sa.String(length=100), nullable=False, unique=True),
        sa.Column('role_key', sa.String(length=50), nullable=False, unique=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('is_system_role', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP'))
    )

    # 4. Create user_organizations table
    op.create_table(
        'user_organizations',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('role_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='pending'),
        sa.Column('joined_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('approved_at', sa.DateTime(), nullable=True),
        sa.Column('approved_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['role_id'], ['roles.id']),
        sa.ForeignKeyConstraint(['approved_by'], ['users.id']),
        sa.UniqueConstraint('user_id', 'organization_id', name='unique_user_org')
    )
    op.create_index('idx_user_orgs_user', 'user_organizations', ['user_id'])
    op.create_index('idx_user_orgs_org', 'user_organizations', ['organization_id'])

    # 5. Create security_questions table
    op.create_table(
        'security_questions',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('question_key', sa.String(length=10), nullable=False, unique=True),
        sa.Column('question_text', sa.Text(), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('display_order', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP'))
    )

    # 6. Create user_security_answers table
    op.create_table(
        'user_security_answers',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('question_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('encrypted_answer', sa.Text(), nullable=False),
        sa.Column('encryption_salt', sa.String(length=64), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['question_id'], ['security_questions.id']),
        sa.UniqueConstraint('user_id', 'question_id', name='unique_user_question')
    )
    op.create_index('idx_security_answers_user', 'user_security_answers', ['user_id'])

    # 7. Create verification_tokens table
    op.create_table(
        'verification_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('token', sa.String(length=255), nullable=False, unique=True),
        sa.Column('token_type', sa.String(length=50), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('used', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('used_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.CheckConstraint(
            "token_type IN ('email_verification', 'password_reset', 'username_recovery')",
            name='check_token_type'
        )
    )
    op.create_index('idx_tokens_token', 'verification_tokens', ['token'])
    op.create_index('idx_tokens_user', 'verification_tokens', ['user_id'])
    op.create_index('idx_tokens_expires', 'verification_tokens', ['expires_at'])

    # 8. Create recovery_attempts table
    op.create_table(
        'recovery_attempts',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('attempt_type', sa.String(length=50), nullable=False),
        sa.Column('success', sa.Boolean(), nullable=False),
        sa.Column('ip_address', sa.String(length=50), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE')
    )
    op.create_index('idx_recovery_user_time', 'recovery_attempts', ['user_id', 'created_at'])

    # 9. Create audit_logs table
    op.create_table(
        'audit_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('action', sa.String(length=100), nullable=False),
        sa.Column('entity_type', sa.String(length=50), nullable=True),
        sa.Column('entity_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('details', postgresql.JSONB(), nullable=True),
        sa.Column('ip_address', sa.String(length=50), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'])
    )
    op.create_index('idx_audit_user', 'audit_logs', ['user_id'])
    op.create_index('idx_audit_org', 'audit_logs', ['organization_id'])
    op.create_index('idx_audit_created', 'audit_logs', ['created_at'])
    op.create_index('idx_audit_action', 'audit_logs', ['action'])

    # Insert default roles
    op.execute("""
        INSERT INTO roles (role_name, role_key, description, is_system_role) VALUES
        ('Owner', 'owner', 'Full access to company resources', true),
        ('Pending User', 'pending_user', 'User awaiting role assignment by admin', true),
        ('Independent User', 'independent_user', 'User without company affiliation', true)
    """)

    # Insert security questions
    op.execute("""
        INSERT INTO security_questions (question_key, question_text, category, display_order) VALUES
        ('Q1', 'What is your mother''s maiden name?', 'personal', 1),
        ('Q2', 'What was the name of your first pet?', 'personal', 2),
        ('Q3', 'In what city were you born?', 'personal', 3),
        ('Q4', 'What is your father''s middle name?', 'personal', 4),
        ('Q5', 'What is the name of your childhood best friend?', 'personal', 5),
        ('Q6', 'What was the model of your first car?', 'memorable_events', 6),
        ('Q7', 'In what year did you graduate high school?', 'memorable_events', 7),
        ('Q8', 'What was the name of your elementary school?', 'memorable_events', 8),
        ('Q9', 'What is your favorite book?', 'preferences', 9),
        ('Q10', 'What is your dream vacation destination?', 'preferences', 10)
    """)


def downgrade() -> None:
    """Drop all tables in reverse order"""

    # Drop indexes first
    op.drop_index('idx_audit_action', 'audit_logs')
    op.drop_index('idx_audit_created', 'audit_logs')
    op.drop_index('idx_audit_org', 'audit_logs')
    op.drop_index('idx_audit_user', 'audit_logs')

    op.drop_index('idx_recovery_user_time', 'recovery_attempts')

    op.drop_index('idx_tokens_expires', 'verification_tokens')
    op.drop_index('idx_tokens_user', 'verification_tokens')
    op.drop_index('idx_tokens_token', 'verification_tokens')

    op.drop_index('idx_security_answers_user', 'user_security_answers')

    op.drop_index('idx_user_orgs_org', 'user_organizations')
    op.drop_index('idx_user_orgs_user', 'user_organizations')

    op.drop_index('idx_organizations_gstin', 'organizations')
    op.drop_index('idx_organizations_name', 'organizations')

    op.drop_index('idx_users_status', 'users')
    op.drop_index('idx_users_email', 'users')
    op.drop_index('idx_users_username', 'users')

    # Drop tables in reverse order of creation (respecting foreign keys)
    op.drop_table('audit_logs')
    op.drop_table('recovery_attempts')
    op.drop_table('verification_tokens')
    op.drop_table('user_security_answers')
    op.drop_table('security_questions')
    op.drop_table('user_organizations')
    op.drop_table('roles')
    op.drop_table('organizations')
    op.drop_table('users')
