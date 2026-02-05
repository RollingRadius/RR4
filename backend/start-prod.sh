#!/bin/bash
# Fleet Management System - Production Startup Script

echo ""
echo "========================================"
echo "Fleet Management System - PRODUCTION"
echo "========================================"
echo ""

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo "[ERROR] .env.production file not found"
    echo ""
    echo "Please create it first:"
    echo "1. Copy .env.production.example to .env.production"
    echo "2. Edit .env.production with your secure credentials"
    echo ""
    echo "Commands to generate secure keys:"
    echo ""
    echo "For SECRET_KEY:"
    echo "openssl rand -hex 32"
    echo ""
    echo "For ENCRYPTION_MASTER_KEY:"
    echo "openssl rand -base64 32"
    echo ""
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] Docker is not running"
    echo "Please start Docker and try again"
    exit 1
fi

echo "[WARNING] You are about to start PRODUCTION environment"
echo ""
echo "Make sure you have:"
echo "- Changed all default passwords in .env.production"
echo "- Generated secure SECRET_KEY and ENCRYPTION_MASTER_KEY"
echo "- Configured CORS_ORIGINS for your domain"
echo ""
read -p "Continue with production startup? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Cancelled."
    exit 0
fi

echo ""
echo "[INFO] Stopping development services..."
docker-compose down > /dev/null 2>&1

echo ""
echo "========================================"
echo "Building Production Images"
echo "========================================"
echo ""

docker-compose -f docker-compose.prod.yml build
if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Production build failed"
    exit 1
fi

echo ""
echo "========================================"
echo "Starting Production Services"
echo "========================================"
echo ""

docker-compose -f docker-compose.prod.yml up -d
if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Failed to start production services"
    exit 1
fi

echo ""
echo "[INFO] Waiting for services to be ready..."
sleep 15

echo ""
echo "[INFO] Running database migrations..."
docker-compose -f docker-compose.prod.yml exec backend alembic upgrade head

echo ""
echo "========================================"
echo "Production Services Status"
echo "========================================"
echo ""

docker-compose -f docker-compose.prod.yml ps

echo ""
echo "========================================"
echo "Production Started Successfully!"
echo "========================================"
echo ""
echo "Backend API:  http://localhost:8000"
echo "API Docs:     http://localhost:8000/docs"
echo "Health:       http://localhost:8000/health"
echo ""
echo "[IMPORTANT] Setup reverse proxy (Nginx) with SSL for production!"
echo "See PRODUCTION_DEPLOYMENT.md for full setup guide"
echo ""
echo "To view logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "To stop:      docker-compose -f docker-compose.prod.yml down"
echo ""
