#!/bin/bash
# reset-migrations.sh - Completely reset migrations and database
# WARNING: This will DELETE all data and migrations!

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${RED}${BOLD}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║             ⚠️  DANGER: COMPLETE MIGRATION RESET  ⚠️           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${RED}This will:${NC}"
echo "  1. Drop ALL tables from the database"
echo "  2. Delete ALL migration files"
echo "  3. Create a fresh initial migration"
echo "  4. Apply the new migration"
echo ""
echo -e "${RED}${BOLD}ALL DATA WILL BE LOST!${NC}"
echo ""
read -p "Type 'RESET EVERYTHING' to continue: " -r
echo ""

if [[ $REPLY != "RESET EVERYTHING" ]]; then
    echo "Operation cancelled"
    exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Dropping all database tables"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Drop all tables
docker-compose exec -T postgres psql -U fleet_user -d fleet_db << 'EOF'
DO $$ DECLARE
    r RECORD;
BEGIN
    -- Drop all tables
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;

    -- Drop alembic version table
    DROP TABLE IF EXISTS alembic_version CASCADE;
END $$;

-- Verify all tables are dropped
SELECT COUNT(*) as remaining_tables FROM pg_tables WHERE schemaname = 'public';
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Backing up existing migrations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BACKUP_DIR="alembic/versions_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ "$(ls -A alembic/versions/*.py 2>/dev/null)" ]; then
    mv alembic/versions/*.py "$BACKUP_DIR/" 2>/dev/null || true
    echo "Backed up to: $BACKUP_DIR"
else
    echo "No existing migrations to backup"
fi

# Keep __pycache__ clean
rm -rf alembic/versions/__pycache__

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Creating fresh initial migration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker-compose exec backend alembic revision --autogenerate -m "initial_schema_fresh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Applying new migration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker-compose exec backend alembic upgrade head

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Verifying database schema"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Checking migration status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker-compose exec backend alembic current

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ Migration Reset Complete!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. Seed initial data: ./start.sh seed"
echo "  2. Test your API: curl http://localhost:8000/health"
echo ""
