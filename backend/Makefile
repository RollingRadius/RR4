# Fleet Management System - Backend Makefile
# Convenient commands for Docker operations

.PHONY: help build up down restart logs shell db-init db-reset db-migrate clean prod-build prod-up prod-down prod-logs

# Default target
help:
	@echo "Fleet Management System - Backend Commands"
	@echo "==========================================="
	@echo ""
	@echo "Development Commands:"
	@echo "  make build        - Build development Docker images"
	@echo "  make up           - Start all services (development)"
	@echo "  make down         - Stop all services"
	@echo "  make restart      - Restart all services"
	@echo "  make logs         - View logs (Ctrl+C to exit)"
	@echo "  make shell        - Open shell in backend container"
	@echo ""
	@echo "Production Commands:"
	@echo "  make prod-build   - Build production Docker images"
	@echo "  make prod-up      - Start production services"
	@echo "  make prod-down    - Stop production services"
	@echo "  make prod-logs    - View production logs"
	@echo "  make prod-shell   - Open shell in production backend"
	@echo ""
	@echo "Database Commands:"
	@echo "  make db-init      - Initialize database (create tables)"
	@echo "  make db-reset     - ⚠️  DELETE ALL DATA and reset database"
	@echo "  make db-migrate   - Run Alembic migrations"
	@echo "  make db-shell     - Open PostgreSQL shell"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  make clean        - Stop services and remove volumes"
	@echo "  make clean-all    - Remove everything (images, volumes, networks)"
	@echo ""

# Build Docker images
build:
	@echo "🔨 Building Docker images..."
	docker-compose build

# Start all services
up:
	@echo "🚀 Starting all services..."
	docker-compose up -d
	@echo "✅ Services started!"
	@echo "📍 Backend API: http://localhost:8000"
	@echo "📍 API Docs: http://localhost:8000/docs"
	@echo "📍 PostgreSQL: localhost:5432"
	@echo "📍 Redis: localhost:6379"

# Stop all services
down:
	@echo "🛑 Stopping all services..."
	docker-compose down
	@echo "✅ Services stopped"

# Restart all services
restart:
	@echo "🔄 Restarting all services..."
	docker-compose restart
	@echo "✅ Services restarted"

# View logs
logs:
	@echo "📜 Viewing logs (Ctrl+C to exit)..."
	docker-compose logs -f

# Open shell in backend container
shell:
	@echo "🐚 Opening shell in backend container..."
	docker-compose exec backend /bin/bash

# Initialize database
db-init:
	@echo "🔧 Initializing database..."
	docker-compose exec backend python init-db.py

# Reset database (with confirmation)
db-reset:
	@echo "⚠️  WARNING: This will DELETE ALL DATA!"
	docker-compose exec -it backend python reset-db.py

# Run Alembic migrations
db-migrate:
	@echo "🔄 Running database migrations..."
	docker-compose exec backend alembic upgrade head
	@echo "✅ Migrations complete"

# Open PostgreSQL shell
db-shell:
	@echo "🐚 Opening PostgreSQL shell..."
	docker-compose exec postgres psql -U fleet_user -d fleet_db

# Clean up (stop services and remove volumes)
clean:
	@echo "🧹 Cleaning up..."
	docker-compose down -v
	@echo "✅ Cleanup complete"

# Clean everything (images, volumes, networks)
clean-all:
	@echo "🧹 Removing everything..."
	docker-compose down -v --rmi all --remove-orphans
	@echo "✅ All cleaned up"

# Quick start (build and start)
start: build up db-migrate
	@echo "✨ Application started successfully!"
	@echo "📍 Visit http://localhost:8000/docs"

# Full reset and restart
reset-start: clean build up db-migrate
	@echo "✨ Application reset and started successfully!"

# ============================================================================
# Production Commands
# ============================================================================

# Build production images
prod-build:
	@echo "🔨 Building production Docker images..."
	docker-compose -f docker-compose.prod.yml build --no-cache
	@echo "✅ Production images built"

# Start production services
prod-up:
	@echo "🚀 Starting production services..."
	docker-compose -f docker-compose.prod.yml up -d
	@echo "✅ Production services started!"
	@echo "📍 Backend API: http://localhost:8000"
	@echo "📍 API Docs: http://localhost:8000/docs"

# Stop production services
prod-down:
	@echo "🛑 Stopping production services..."
	docker-compose -f docker-compose.prod.yml down
	@echo "✅ Production services stopped"

# View production logs
prod-logs:
	@echo "📜 Viewing production logs (Ctrl+C to exit)..."
	docker-compose -f docker-compose.prod.yml logs -f

# Open shell in production backend
prod-shell:
	@echo "🐚 Opening shell in production backend container..."
	docker-compose -f docker-compose.prod.yml exec backend /bin/bash

# Production database migrate
prod-db-migrate:
	@echo "🔄 Running production database migrations..."
	docker-compose -f docker-compose.prod.yml exec backend alembic upgrade head
	@echo "✅ Production migrations complete"

# Production quick start
prod-start: prod-build prod-up prod-db-migrate
	@echo "✨ Production application started successfully!"
	@echo "📍 Visit http://localhost:8000/docs"
