#!/bin/bash
set -e

echo "🚀 Fleet Management System - Starting..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
while ! pg_isready -h postgres -U fleet_user -d fleet_db > /dev/null 2>&1; do
  echo "   Waiting for PostgreSQL..."
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Run database migrations
echo "🔄 Running database migrations..."
alembic upgrade head
echo "✅ Migrations completed!"

# Execute the main command
echo "🎯 Starting FastAPI application..."
exec "$@"
