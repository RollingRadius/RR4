#!/bin/bash

# Fleet Management System - Docker Startup Script
# Enhanced version with migration handling and troubleshooting

set -e

# ============================================================================
# Colors and Formatting
# ============================================================================
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

COMMAND="${1:-dev}"

# ============================================================================
# Helper Functions
# ============================================================================
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}$1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
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

print_step() {
    echo -e "${CYAN}━━━ $1${NC}"
}

# ============================================================================
# Docker Checks
# ============================================================================
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker is running"
}

check_docker_compose() {
    if docker compose version > /dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif docker-compose version > /dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        print_error "docker-compose is not installed"
        exit 1
    fi
    print_success "Docker Compose is available ($COMPOSE_CMD)"
}

# ============================================================================
# Service Management
# ============================================================================
start_dev() {
    print_header "Fleet Management System - Development Mode"

    check_docker
    check_docker_compose

    print_step "Step 1: Building images..."
    $COMPOSE_CMD build

    print_step "Step 2: Starting services..."
    $COMPOSE_CMD up -d

    print_step "Step 3: Waiting for services to be healthy..."
    sleep 5

    # Show service status
    echo ""
    $COMPOSE_CMD ps

    echo ""
    print_success "Services started successfully!"
    echo ""
    print_info "Access Points:"
    echo "  🌐 Backend API:    http://localhost:8000"
    echo "  📚 API Docs:       http://localhost:8000/docs"
    echo "  🗄️  PostgreSQL:     localhost:5432"
    echo "  🔴 Redis:          localhost:6379"
    echo ""
    print_info "Useful Commands:"
    echo "  View logs:         ${BOLD}./start.sh logs${NC}"
    echo "  View backend logs: ${BOLD}./start.sh logs backend${NC}"
    echo "  Check status:      ${BOLD}./start.sh status${NC}"
    echo "  Run migrations:    ${BOLD}./start.sh migrate${NC}"
    echo "  Open shell:        ${BOLD}./start.sh shell${NC}"
    echo "  Stop services:     ${BOLD}./start.sh down${NC}"
    echo ""

    # Check if services are healthy
    print_step "Step 4: Checking service health..."
    sleep 10

    BACKEND_HEALTHY=$($COMPOSE_CMD ps backend | grep -c "healthy" || echo "0")

    if [ "$BACKEND_HEALTHY" -eq "0" ]; then
        print_warning "Backend might not be healthy yet. Checking logs..."
        echo ""
        $COMPOSE_CMD logs --tail=30 backend
        echo ""
        print_info "If you see migration errors, try:"
        echo "  1. Check database: ${BOLD}./start.sh exec backend alembic current${NC}"
        echo "  2. View migrations: ${BOLD}./start.sh exec backend alembic history${NC}"
        echo "  3. Fix migrations: ${BOLD}./start.sh fix-migrations${NC}"
    else
        print_success "Backend is healthy!"
    fi
}

start_prod() {
    print_header "Fleet Management System - Production Mode"

    check_docker
    check_docker_compose

    print_warning "Starting in PRODUCTION mode"
    echo ""
    print_info "This will:"
    echo "  - Use production Docker target"
    echo "  - Run with multiple workers"
    echo "  - Use production environment variables"
    echo ""
    read -p "Continue? (yes/no): " -r

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Operation cancelled"
        exit 0
    fi

    print_step "Building production images..."
    $COMPOSE_CMD -f docker-compose.yml -f docker-compose.prod.yml build

    print_step "Starting production services..."
    $COMPOSE_CMD -f docker-compose.yml -f docker-compose.prod.yml up -d

    print_success "Production services started!"
    print_info "Backend API: http://localhost:8000"
}

# ============================================================================
# Maintenance Operations
# ============================================================================
stop_services() {
    print_info "Stopping all services..."
    check_docker_compose

    $COMPOSE_CMD down

    print_success "All services stopped"
}

stop_with_volumes() {
    print_warning "⚠️  WARNING: This will DELETE all database data!"
    echo ""
    print_info "This will remove:"
    echo "  - All Docker containers"
    echo "  - All Docker volumes (database data, Redis data)"
    echo "  - Docker networks"
    echo ""
    read -p "Are you sure? Type 'YES' to confirm: " -r

    if [[ $REPLY == "YES" ]]; then
        check_docker_compose
        print_step "Stopping services and removing volumes..."
        $COMPOSE_CMD down -v
        print_success "Services stopped and volumes removed"
    else
        print_info "Operation cancelled"
    fi
}

# ============================================================================
# Logging and Status
# ============================================================================
show_logs() {
    check_docker_compose

    SERVICE="${2:-}"
    if [ -z "$SERVICE" ]; then
        print_info "Showing logs for all services (Ctrl+C to exit)"
        echo ""
        $COMPOSE_CMD logs -f
    else
        print_info "Showing logs for $SERVICE (Ctrl+C to exit)"
        echo ""
        $COMPOSE_CMD logs -f "$SERVICE"
    fi
}

show_status() {
    check_docker_compose

    print_header "Service Status"
    $COMPOSE_CMD ps

    echo ""
    print_info "Container Health:"
    docker ps --filter "name=fleet_" --format "table {{.Names}}\t{{.Status}}"
}

# ============================================================================
# Database Operations
# ============================================================================
run_migrations() {
    check_docker_compose

    print_header "Running Database Migrations"

    # Check if backend is running
    if ! $COMPOSE_CMD ps backend | grep -q "Up"; then
        print_error "Backend container is not running. Start services first:"
        echo "  ./start.sh dev"
        exit 1
    fi

    print_step "Checking current migration status..."
    $COMPOSE_CMD exec backend alembic current || true

    echo ""
    print_step "Running migrations..."
    if $COMPOSE_CMD exec backend alembic upgrade head; then
        print_success "Migrations completed successfully!"
    else
        print_error "Migration failed!"
        echo ""
        print_info "Troubleshooting steps:"
        echo "  1. Check migration history: ./start.sh exec backend alembic history"
        echo "  2. Check for multiple heads: ./start.sh exec backend alembic heads"
        echo "  3. View backend logs: ./start.sh logs backend"
        exit 1
    fi
}

fix_migrations() {
    check_docker_compose

    print_header "Migration Troubleshooting & Fix"

    print_step "Step 1: Checking migration heads..."
    $COMPOSE_CMD exec backend alembic heads

    echo ""
    print_step "Step 2: Checking migration history..."
    $COMPOSE_CMD exec backend alembic history | head -20

    echo ""
    print_step "Step 3: Checking current version..."
    $COMPOSE_CMD exec backend alembic current || true

    echo ""
    HEADS_COUNT=$($COMPOSE_CMD exec backend alembic heads 2>/dev/null | grep -c "^[a-f0-9]" || echo "0")

    if [ "$HEADS_COUNT" -gt 1 ]; then
        print_warning "Multiple migration heads detected!"
        echo ""
        print_info "Attempting to upgrade to all heads..."

        if $COMPOSE_CMD exec backend alembic upgrade heads; then
            print_success "Successfully upgraded to all heads!"
        else
            print_error "Failed to upgrade to all heads"
            echo ""
            print_info "You may need to merge the heads manually:"
            echo "  ./start.sh exec backend alembic merge heads -m \"merge migration heads\""
        fi
    else
        print_info "Single migration head detected (normal)"
        echo ""
        print_step "Attempting standard migration..."
        $COMPOSE_CMD exec backend alembic upgrade head
    fi

    echo ""
    print_step "Step 4: Verifying database tables..."
    $COMPOSE_CMD exec postgres psql -U fleet_user -d fleet_db -c "\dt" | grep "public" || true

    echo ""
    print_success "Migration troubleshooting complete!"
}

init_database() {
    check_docker_compose

    print_header "Database Initialization"

    print_warning "This will initialize the database using init-db.py"
    print_info "Note: Alembic migrations are preferred over init-db.py"
    echo ""
    read -p "Continue? (yes/no): " -r

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Operation cancelled"
        exit 0
    fi

    $COMPOSE_CMD exec backend python init-db.py
}

seed_data() {
    check_docker_compose

    print_header "Seeding Database"

    print_step "Loading seed data..."
    if $COMPOSE_CMD exec backend python seed_capabilities.py; then
        print_success "Seed data loaded successfully!"
    else
        print_warning "Seed data might already exist"
    fi
}

# ============================================================================
# Shell Access
# ============================================================================
open_shell() {
    check_docker_compose

    print_info "Opening bash shell in backend container..."
    print_info "Type 'exit' to close the shell"
    echo ""
    $COMPOSE_CMD exec backend bash
}

exec_backend() {
    check_docker_compose

    shift  # Remove 'exec' argument
    print_info "Executing command in backend container..."
    echo ""
    $COMPOSE_CMD exec backend "$@"
}

# ============================================================================
# Rebuild Operations
# ============================================================================
rebuild_services() {
    print_header "Rebuilding Services"

    check_docker
    check_docker_compose

    print_warning "This will rebuild all Docker images from scratch"
    echo ""
    read -p "Continue? (yes/no): " -r

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Operation cancelled"
        exit 0
    fi

    print_step "Step 1: Stopping services..."
    $COMPOSE_CMD down

    print_step "Step 2: Rebuilding images (no cache)..."
    $COMPOSE_CMD build --no-cache

    print_step "Step 3: Starting services..."
    $COMPOSE_CMD up -d

    print_success "Services rebuilt and started successfully!"
}

# ============================================================================
# Fresh Start (Nuclear Option)
# ============================================================================
fresh_start() {
    print_header "Fresh Start - Complete Reset"

    echo -e "${RED}${BOLD}⚠️  DANGER ZONE ⚠️${NC}"
    echo ""
    print_warning "This will:"
    echo "  1. Stop all services"
    echo "  2. Remove all containers"
    echo "  3. Delete all volumes (ALL DATABASE DATA WILL BE LOST)"
    echo "  4. Rebuild all images from scratch"
    echo "  5. Start fresh services"
    echo ""
    echo -e "${RED}${BOLD}THIS CANNOT BE UNDONE!${NC}"
    echo ""
    read -p "Type 'DELETE EVERYTHING' to confirm: " -r

    if [[ $REPLY == "DELETE EVERYTHING" ]]; then
        check_docker_compose

        print_step "Step 1: Stopping and removing everything..."
        $COMPOSE_CMD down -v

        print_step "Step 2: Rebuilding images..."
        $COMPOSE_CMD build --no-cache

        print_step "Step 3: Starting fresh services..."
        $COMPOSE_CMD up -d

        print_step "Step 4: Waiting for database to be ready..."
        sleep 15

        print_step "Step 5: Running migrations..."
        $COMPOSE_CMD exec backend alembic upgrade head

        print_success "Fresh start complete! Your database is now clean."
        echo ""
        print_info "You may want to seed initial data:"
        echo "  ./start.sh seed"
    else
        print_info "Operation cancelled (smart choice!)"
    fi
}

# ============================================================================
# Help
# ============================================================================
show_help() {
    echo -e "${BOLD}Fleet Management System - Docker Control Script${NC}"
    echo ""
    echo "Usage: ./start.sh [command]"
    echo ""
    echo -e "${CYAN}Service Management:${NC}"
    echo "  dev              Start services in development mode (default)"
    echo "  prod             Start services in production mode"
    echo "  down             Stop all services"
    echo "  clean            Stop services and remove volumes (deletes data)"
    echo "  restart          Restart all services"
    echo "  rebuild          Rebuild all services from scratch"
    echo "  fresh            Complete reset - rebuild everything and wipe data"
    echo ""
    echo -e "${CYAN}Database Operations:${NC}"
    echo "  migrate          Run database migrations"
    echo "  fix-migrations   Troubleshoot and fix migration issues"
    echo "  init-db          Initialize database (not recommended - use migrations)"
    echo "  seed             Load seed data into database"
    echo ""
    echo -e "${CYAN}Monitoring & Debugging:${NC}"
    echo "  status           Show status of all services"
    echo "  logs [service]   Show logs (optionally for specific service)"
    echo "  shell            Open bash shell in backend container"
    echo "  exec <cmd>       Execute command in backend container"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./start.sh                    # Start in development mode"
    echo "  ./start.sh logs backend       # Show backend logs"
    echo "  ./start.sh exec alembic current  # Check migration status"
    echo "  ./start.sh fix-migrations     # Fix migration conflicts"
    echo ""
}

# ============================================================================
# Command Router
# ============================================================================
case "$COMMAND" in
    dev|start)
        start_dev
        ;;
    prod|production)
        start_prod
        ;;
    down|stop)
        stop_services
        ;;
    clean|reset)
        stop_with_volumes
        ;;
    restart)
        stop_services
        start_dev
        ;;
    logs)
        show_logs "$@"
        ;;
    rebuild)
        rebuild_services
        ;;
    fresh|nuke)
        fresh_start
        ;;
    status|ps)
        show_status
        ;;
    shell|bash)
        open_shell
        ;;
    exec)
        exec_backend "$@"
        ;;
    migrate|migration)
        run_migrations
        ;;
    fix-migrations|fix)
        fix_migrations
        ;;
    init-db|init)
        init_database
        ;;
    seed|seed-data)
        seed_data
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
