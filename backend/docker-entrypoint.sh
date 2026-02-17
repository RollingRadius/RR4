#!/bin/bash
set -e

echo "🚀 Fleet Management System - Starting..."
echo "================================================"

# Wait for PostgreSQL to be ready with retry logic
MAX_RETRIES=30
RETRY_COUNT=0

echo "⏳ Waiting for PostgreSQL to be ready..."
while ! pg_isready -h postgres -U fleet_user -d fleet_db > /dev/null 2>&1; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "❌ PostgreSQL failed to start after $MAX_RETRIES attempts"
    exit 1
  fi
  echo "   Waiting for PostgreSQL... ($RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
RETRY_COUNT=0
while ! nc -z redis 6379 > /dev/null 2>&1; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge 15 ]; then
    echo "⚠️  Redis connection timeout, continuing anyway..."
    break
  fi
  echo "   Waiting for Redis... ($RETRY_COUNT/15)"
  sleep 1
done
if [ $RETRY_COUNT -lt 15 ]; then
  echo "✅ Redis is ready!"
fi

# Run database initialization if INIT_DB is set
if [ "$INIT_DB" = "true" ]; then
  echo "🔧 Initializing database..."
  python init-db.py || echo "⚠️  Database initialization failed or already initialized"
fi

# Run database migrations
echo "🔄 Running database migrations..."
if command -v alembic > /dev/null 2>&1; then
  alembic upgrade head && echo "✅ Migrations completed!" || {
    echo "⚠️  Database migration failed, but continuing..."
    echo "   You may need to run migrations manually: docker-compose exec backend alembic upgrade head"
  }
else
  echo "❌ Alembic not found in PATH!"
  echo "   PATH=$PATH"
  exit 1
fi

# Execute the main command
echo "================================================"
echo "🎯 Starting FastAPI application..."
echo "   Environment: ${ENVIRONMENT:-development}"
echo "   Port: ${PORT:-8000}"
echo "================================================"
exec "$@"
