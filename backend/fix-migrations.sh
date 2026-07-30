#!/bin/bash

# Fix Database Migrations - Handle Multiple Heads
echo "=========================================="
echo "Fixing Database Migrations"
echo "=========================================="
echo ""

# Step 1: Show current migration heads
echo "[1/4] Checking migration heads..."
docker-compose exec -T backend alembic heads

echo ""
echo "[2/4] Showing migration history..."
docker-compose exec -T backend alembic history | head -20

echo ""
echo "[3/4] Upgrading to all heads..."
# Instead of 'head', use 'heads' to upgrade all branches
docker-compose exec -T backend alembic upgrade heads

echo ""
echo "[4/4] Verifying database tables..."
docker-compose exec -T postgres psql -U fleet_user -d fleet_db -c "\dt" | grep "public"

echo ""
echo "=========================================="
echo "✅ Migration fix complete!"
echo "=========================================="
echo ""
echo "Now run: docker-compose exec backend python seed_capabilities.py"
echo ""
