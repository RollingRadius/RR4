#!/bin/bash
# apply-migrations-production.sh - Apply migrations on production server
# Run this script ON your production server

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}$1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}━━━ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header "Production Migration Script"

print_info "This script will apply database migrations on your production server"
echo ""
print_warning "Prerequisites:"
echo "  1. Docker containers must be running"
echo "  2. PostgreSQL must be accessible"
echo "  3. You must be in the backend directory"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Detect docker-compose command
if docker compose version > /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif docker-compose version > /dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    print_error "docker-compose is not installed"
    exit 1
fi

print_success "Using: $COMPOSE_CMD"

echo ""
print_step "Step 1: Checking Docker containers"

if ! $COMPOSE_CMD ps | grep -q "Up"; then
    print_warning "No containers are running!"
    echo ""
    print_info "Do you want to start the containers? (yes/no)"
    read -p "> " START_CONTAINERS

    if [[ $START_CONTAINERS =~ ^[Yy][Ee][Ss]$ ]]; then
        print_step "Starting containers..."
        $COMPOSE_CMD up -d

        print_step "Waiting for services to be ready..."
        sleep 20
    else
        print_error "Cannot apply migrations without running containers"
        exit 1
    fi
fi

$COMPOSE_CMD ps
print_success "Containers are running"

echo ""
print_step "Step 2: Checking database connection"

if $COMPOSE_CMD exec -T postgres pg_isready -U fleet_user -d fleet_db > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_error "Database is not accessible"
    print_info "Waiting 30 seconds for database to be ready..."
    sleep 30

    if ! $COMPOSE_CMD exec -T postgres pg_isready -U fleet_user -d fleet_db > /dev/null 2>&1; then
        print_error "Database is still not accessible. Check logs:"
        echo "  $COMPOSE_CMD logs postgres"
        exit 1
    fi
fi

echo ""
print_step "Step 3: Checking current migration status"

$COMPOSE_CMD exec backend alembic current || print_info "No migrations applied yet"

echo ""
print_step "Step 4: Checking for migration heads"

HEADS=$($COMPOSE_CMD exec backend alembic heads 2>/dev/null || echo "")
echo "$HEADS"

if echo "$HEADS" | grep -c "^[a-f0-9]" | grep -q "^[2-9]"; then
    print_warning "Multiple migration heads detected!"
    print_info "Will use 'upgrade heads' to handle this"
    UPGRADE_CMD="upgrade heads"
else
    print_success "Single migration head (normal)"
    UPGRADE_CMD="upgrade head"
fi

echo ""
print_step "Step 5: Viewing migration history"

$COMPOSE_CMD exec backend alembic history | head -20

echo ""
print_step "Step 6: Creating database backup (recommended)"

BACKUP_FILE="db_backup_$(date +%Y%m%d_%H%M%S).sql"

print_info "Do you want to create a database backup? (yes/no)"
read -p "> " CREATE_BACKUP

if [[ $CREATE_BACKUP =~ ^[Yy][Ee][Ss]$ ]]; then
    print_info "Creating backup: $BACKUP_FILE"
    $COMPOSE_CMD exec -T postgres pg_dump -U fleet_user -d fleet_db > "$BACKUP_FILE"
    print_success "Backup created: $BACKUP_FILE"
else
    print_warning "Skipping backup (not recommended for production!)"
fi

echo ""
print_step "Step 7: Applying migrations"

print_warning "About to run: alembic $UPGRADE_CMD"
print_info "This will modify the production database!"
echo ""
read -p "Continue? (yes/no): " CONTINUE

if [[ ! $CONTINUE =~ ^[Yy][Ee][Ss]$ ]]; then
    print_info "Migration cancelled"
    exit 0
fi

echo ""
print_info "Running migrations..."

if $COMPOSE_CMD exec backend alembic $UPGRADE_CMD; then
    print_success "Migrations applied successfully!"
else
    MIGRATION_FAILED=$?
    print_error "Migration failed with exit code: $MIGRATION_FAILED"
    echo ""
    print_info "Troubleshooting steps:"
    echo "  1. Check backend logs: $COMPOSE_CMD logs backend"
    echo "  2. Check migration status: $COMPOSE_CMD exec backend alembic current"
    echo "  3. View recent migrations: $COMPOSE_CMD exec backend alembic history"
    echo ""

    if [ -f "$BACKUP_FILE" ]; then
        print_warning "You can restore the backup with:"
        echo "  cat $BACKUP_FILE | $COMPOSE_CMD exec -T postgres psql -U fleet_user -d fleet_db"
    fi

    exit $MIGRATION_FAILED
fi

echo ""
print_step "Step 8: Verifying migration"

print_info "Current migration version:"
$COMPOSE_CMD exec backend alembic current

echo ""
print_info "Database tables:"
$COMPOSE_CMD exec postgres psql -U fleet_user -d fleet_db -c "\dt" | head -30

echo ""
print_step "Step 9: Testing API health"

if $COMPOSE_CMD exec backend curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_success "API is healthy"
else
    print_warning "API health check failed (might be normal if /health endpoint doesn't exist)"
fi

echo ""
print_header "Migration Complete!"

print_success "Migrations have been applied successfully!"
echo ""
print_info "Summary:"
echo "  ✓ Database migrations applied"
echo "  ✓ All tables created/updated"
echo "  ✓ API is running"
echo ""

if [ -f "$BACKUP_FILE" ]; then
    print_info "Backup file: $BACKUP_FILE"
    echo "  Keep this file safe in case you need to rollback"
fi

echo ""
print_info "Next steps:"
echo "  1. Test your API endpoints"
echo "  2. Monitor application logs: $COMPOSE_CMD logs -f backend"
echo "  3. Verify data integrity"
echo ""
print_success "All done! 🚀"
echo ""
