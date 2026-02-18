#!/bin/bash
# docker-entrypoint.sh - Enhanced entrypoint with robust migration handling
# Handles database initialization, migrations, and application startup

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Fleet Management System - Container Startup                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# STEP 1: Wait for PostgreSQL to be ready
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Waiting for PostgreSQL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "/app/wait-for-db.sh" ]; then
    /app/wait-for-db.sh
else
    # Fallback if wait-for-db.sh is not available
    echo "⚠️  wait-for-db.sh not found, using fallback method..."
    MAX_RETRIES=30
    RETRY_COUNT=0

    while ! pg_isready -h "${DB_HOST:-postgres}" -U "${DB_USER:-fleet_user}" -d "${DB_NAME:-fleet_db}" -q; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "❌ PostgreSQL failed to start after $MAX_RETRIES attempts"
            exit 1
        fi
        echo "   Waiting for PostgreSQL... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
    done
    echo "✅ PostgreSQL is ready!"
fi

# ============================================================================
# STEP 2: Wait for Redis (if configured)
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Waiting for Redis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "${REDIS_URL:-}" ] || [ -n "${REDIS_HOST:-}" ]; then
    REDIS_HOST="${REDIS_HOST:-redis}"
    REDIS_PORT="${REDIS_PORT:-6379}"
    MAX_RETRIES=15
    RETRY_COUNT=0

    while ! nc -z "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "⚠️  Redis connection timeout, continuing without Redis..."
            break
        fi
        echo "   Waiting for Redis... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 1
    done

    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "✅ Redis is ready!"
    fi
else
    echo "⏭️  Redis not configured, skipping..."
fi

# ============================================================================
# STEP 3: Database Migration Strategy
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Database Migration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Alembic is available
if ! command -v alembic &> /dev/null; then
    echo "❌ ERROR: Alembic not found in PATH!"
    echo "   PATH=$PATH"
    echo "   This is a critical error. Please check your Dockerfile."
    exit 1
fi

echo "✅ Alembic found: $(which alembic)"

# Check if alembic.ini exists
if [ ! -f "/app/alembic.ini" ]; then
    echo "❌ ERROR: alembic.ini not found!"
    exit 1
fi

# Check current migration status
echo ""
echo "📊 Checking current migration status..."
if alembic current 2>/dev/null; then
    echo "✅ Alembic is properly configured"
else
    echo "⚠️  No migrations applied yet (this is normal for fresh database)"
fi

# Check for multiple migration heads (branching issue)
echo ""
echo "🔍 Checking for migration conflicts..."
HEADS_COUNT=$(alembic heads 2>/dev/null | grep -c "^[a-f0-9]" || echo "0")

if [ "$HEADS_COUNT" -gt 1 ]; then
    echo "⚠️  WARNING: Multiple migration heads detected ($HEADS_COUNT heads)"
    echo "   This usually happens when migrations were created on different branches."
    echo "   Attempting to upgrade to all heads..."

    if alembic upgrade heads; then
        echo "✅ Successfully upgraded to all heads!"
    else
        echo "❌ ERROR: Failed to upgrade to all heads"
        echo "   Manual intervention required. Run:"
        echo "   docker-compose exec backend alembic merge heads -m 'merge migration heads'"
        exit 1
    fi
elif [ "$HEADS_COUNT" -eq 1 ]; then
    echo "✅ Single migration head detected (normal)"
    echo ""
    echo "🔄 Running database migrations..."

    if alembic upgrade head; then
        echo "✅ Migrations completed successfully!"
    else
        MIGRATION_EXIT_CODE=$?
        echo "❌ ERROR: Migration failed with exit code $MIGRATION_EXIT_CODE"
        echo ""
        echo "Common causes:"
        echo "  1. Migration script has syntax errors"
        echo "  2. Database schema conflicts"
        echo "  3. Constraint violations"
        echo ""
        echo "Debug commands:"
        echo "  docker-compose exec backend alembic current"
        echo "  docker-compose exec backend alembic history"
        echo "  docker-compose logs postgres"
        echo ""

        # Don't exit immediately - allow for manual intervention in development
        if [ "${ENVIRONMENT:-development}" = "production" ]; then
            echo "⚠️  Production mode - exiting due to migration failure"
            exit $MIGRATION_EXIT_CODE
        else
            echo "⚠️  Development mode - continuing despite migration failure"
            echo "   You can fix migrations manually and restart the container"
        fi
    fi
else
    echo "⚠️  No migration heads found - database might be empty"
    echo "   Attempting to run migrations anyway..."

    if alembic upgrade head; then
        echo "✅ Initial migrations applied successfully!"
    else
        echo "❌ Migration failed - this might be the first run"
    fi
fi

# ============================================================================
# STEP 4: Database Initialization (Optional)
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Database Initialization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "${RUN_INIT_DB:-false}" = "true" ]; then
    echo "🔧 Running database initialization..."
    if [ -f "/app/init-db.py" ]; then
        if python /app/init-db.py; then
            echo "✅ Database initialization completed!"
        else
            echo "⚠️  Database initialization failed or already initialized"
        fi
    else
        echo "⚠️  init-db.py not found, skipping..."
    fi
else
    echo "⏭️  Database initialization skipped (set RUN_INIT_DB=true to enable)"
fi

# ============================================================================
# STEP 5: Run Seed Data (Optional)
# ============================================================================
if [ "${RUN_SEED_DATA:-false}" = "true" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Step 5: Seeding Initial Data"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ -f "/app/seed_capabilities.py" ]; then
        echo "🌱 Seeding capabilities..."
        if python /app/seed_capabilities.py; then
            echo "✅ Seed data loaded successfully!"
        else
            echo "⚠️  Seed data loading failed or already exists"
        fi
    else
        echo "⏭️  No seed scripts found, skipping..."
    fi
fi

# ============================================================================
# STEP 6: Start Application
# ============================================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🚀 Starting Application                                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Environment: ${ENVIRONMENT:-development}"
echo "Port: ${PORT:-8000}"
echo "Workers: ${WORKERS:-1}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Execute the main command (usually uvicorn)
exec "$@"
