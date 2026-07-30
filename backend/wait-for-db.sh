#!/bin/bash
# wait-for-db.sh - Robust database readiness checker
# Waits for PostgreSQL to be fully ready for connections and migrations

set -e

# Configuration
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-fleet_user}"
DB_NAME="${DB_NAME:-fleet_db}"
MAX_RETRIES="${DB_MAX_RETRIES:-60}"
RETRY_INTERVAL="${DB_RETRY_INTERVAL:-2}"

echo "⏳ Waiting for PostgreSQL to be ready..."
echo "   Host: $DB_HOST:$DB_PORT"
echo "   Database: $DB_NAME"
echo "   User: $DB_USER"
echo ""

# Function to check if PostgreSQL is ready
check_postgres() {
    pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -q
    return $?
}

# Function to verify database exists and is accessible
verify_database() {
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1
    return $?
}

# Wait for PostgreSQL to accept connections
RETRY_COUNT=0
while ! check_postgres; do
    RETRY_COUNT=$((RETRY_COUNT + 1))

    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "❌ ERROR: PostgreSQL not ready after $MAX_RETRIES attempts ($(($MAX_RETRIES * $RETRY_INTERVAL))s)"
        echo "   This usually means:"
        echo "   1. PostgreSQL container is not running"
        echo "   2. Database credentials are incorrect"
        echo "   3. Network connectivity issues"
        echo ""
        echo "   Debug commands:"
        echo "   - docker-compose ps"
        echo "   - docker-compose logs postgres"
        exit 1
    fi

    # Show progress every 5 attempts
    if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
        echo "   Still waiting... ($RETRY_COUNT/$MAX_RETRIES) - $(($RETRY_COUNT * $RETRY_INTERVAL))s elapsed"
    fi

    sleep $RETRY_INTERVAL
done

echo "✅ PostgreSQL is accepting connections!"

# Additional verification - ensure database is accessible
echo "🔍 Verifying database accessibility..."
RETRY_COUNT=0
while ! verify_database; do
    RETRY_COUNT=$((RETRY_COUNT + 1))

    if [ $RETRY_COUNT -ge 10 ]; then
        echo "❌ ERROR: Database exists but is not accessible"
        exit 1
    fi

    echo "   Waiting for database to be accessible... ($RETRY_COUNT/10)"
    sleep 1
done

echo "✅ Database is fully accessible!"
echo "✅ PostgreSQL is READY for migrations and application startup"
echo ""
