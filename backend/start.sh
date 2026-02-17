#!/bin/bash

# Fleet Management System - Docker Startup Script
# Usage: ./start.sh [dev|prod|down|logs|rebuild]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Default command
COMMAND="${1:-dev}"

# Function to print colored messages
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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if docker compose version > /dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif docker-compose version > /dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        print_error "docker-compose is not installed"
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to start services in development mode
start_dev() {
    print_info "Starting Fleet Management System in DEVELOPMENT mode..."
    check_docker
    check_docker_compose

    # Build and start services
    $COMPOSE_CMD up --build -d

    print_success "Services started successfully!"
    print_info "Access points:"
    echo "  - Backend API: http://localhost:8000"
    echo "  - API Docs: http://localhost:8000/docs"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo ""
    print_info "View logs with: ./start.sh logs"
    print_info "Stop services with: ./start.sh down"
}

# Function to start services in production mode
start_prod() {
    print_info "Starting Fleet Management System in PRODUCTION mode..."
    check_docker
    check_docker_compose

    # Build production target
    $COMPOSE_CMD -f docker-compose.yml -f docker-compose.prod.yml up --build -d

    print_success "Production services started successfully!"
    print_info "Backend API: http://localhost:8000"
}

# Function to stop all services
stop_services() {
    print_info "Stopping all services..."
    check_docker_compose

    $COMPOSE_CMD down

    print_success "All services stopped"
}

# Function to stop and remove volumes
stop_with_volumes() {
    print_warning "Stopping all services and removing volumes..."
    print_warning "This will DELETE all database data!"
    read -p "Are you sure? (yes/no): " -n 3 -r
    echo
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        check_docker_compose
        $COMPOSE_CMD down -v
        print_success "Services stopped and volumes removed"
    else
        print_info "Operation cancelled"
    fi
}

# Function to show logs
show_logs() {
    check_docker_compose

    SERVICE="${2:-}"
    if [ -z "$SERVICE" ]; then
        print_info "Showing logs for all services (Ctrl+C to exit)..."
        $COMPOSE_CMD logs -f
    else
        print_info "Showing logs for $SERVICE (Ctrl+C to exit)..."
        $COMPOSE_CMD logs -f "$SERVICE"
    fi
}

# Function to rebuild services
rebuild_services() {
    print_info "Rebuilding all services..."
    check_docker
    check_docker_compose

    $COMPOSE_CMD build --no-cache
    $COMPOSE_CMD up -d

    print_success "Services rebuilt and started"
}

# Function to show service status
show_status() {
    check_docker_compose

    print_info "Service Status:"
    $COMPOSE_CMD ps
}

# Function to execute command in backend container
exec_backend() {
    check_docker_compose

    print_info "Executing command in backend container..."
    shift  # Remove 'exec' argument
    $COMPOSE_CMD exec backend "$@"
}

# Function to open backend shell
open_shell() {
    check_docker_compose

    print_info "Opening shell in backend container..."
    $COMPOSE_CMD exec backend bash
}

# Function to run database migrations
run_migrations() {
    check_docker_compose

    print_info "Running database migrations..."
    $COMPOSE_CMD exec backend alembic upgrade head
    print_success "Migrations completed"
}

# Function to initialize database
init_database() {
    check_docker_compose

    print_info "Initializing database..."
    $COMPOSE_CMD exec backend python init-db.py
    print_success "Database initialized"
}

# Function to show help
show_help() {
    echo "Fleet Management System - Docker Control Script"
    echo ""
    echo "Usage: ./start.sh [command]"
    echo ""
    echo "Commands:"
    echo "  dev              Start services in development mode (default)"
    echo "  prod             Start services in production mode"
    echo "  down             Stop all services"
    echo "  clean            Stop services and remove volumes (deletes data)"
    echo "  logs [service]   Show logs (optionally for specific service)"
    echo "  rebuild          Rebuild all services from scratch"
    echo "  status           Show status of all services"
    echo "  shell            Open bash shell in backend container"
    echo "  exec <cmd>       Execute command in backend container"
    echo "  migrate          Run database migrations"
    echo "  init-db          Initialize database with seed data"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./start.sh              # Start in development mode"
    echo "  ./start.sh logs backend # Show backend logs"
    echo "  ./start.sh exec python init-db.py"
    echo ""
}

# Main command handler
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
    logs)
        show_logs "$@"
        ;;
    rebuild)
        rebuild_services
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
    init-db|init)
        init_database
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
