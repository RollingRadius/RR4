#!/bin/bash

# Fleet Management System - Docker Start Script
# This script starts all backend services using Docker Compose

set -e

echo "🚀 Fleet Management System - Docker Startup"
echo "=============================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "   Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Wait for Docker to be ready
echo "⏳ Checking Docker status..."
MAX_RETRIES=30
RETRY_COUNT=0

while ! docker info &> /dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "❌ Docker is not responding after 60 seconds!"
        echo ""
        echo "Please ensure:"
        echo "  1. Docker Desktop is installed"
        echo "  2. Docker Desktop is running (check system tray)"
        echo "  3. Docker engine has fully started (may take 1-2 minutes)"
        echo ""
        echo "Then try again: ./start.sh"
        exit 1
    fi

    if [ $RETRY_COUNT -eq 1 ]; then
        echo "   Docker is starting up... (this may take 1-2 minutes)"
    fi

    echo "   Waiting for Docker... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

echo "✅ Docker is ready!"
echo ""

# Create necessary directories
echo "📁 Creating required directories..."
mkdir -p uploads/logos
mkdir -p logs
mkdir -p osrm-data
echo "✅ Directories created"
echo ""

# Check for .env.docker file
if [ ! -f .env.docker ]; then
    echo "⚠️  Warning: .env.docker file not found"
    echo "   Using default environment variables from docker-compose.yml"
    echo ""
fi

# Stop any existing containers
echo "🛑 Stopping existing containers (if any)..."
docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
echo ""

# Build and start services
echo "🔨 Building and starting services..."
echo "   This may take a few minutes on first run..."
echo ""

# Try docker compose (new syntax) first, fallback to docker-compose
if docker compose version &> /dev/null; then
    docker compose up -d --build
else
    docker-compose up -d --build
fi

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check service status
echo ""
echo "📊 Service Status:"
echo "=================="
if docker compose version &> /dev/null; then
    docker compose ps
else
    docker-compose ps
fi

echo ""
echo "🎉 Fleet Management System Started Successfully!"
echo ""
echo "📍 Service Endpoints:"
echo "   Backend API:  http://localhost:8000"
echo "   API Docs:     http://localhost:8000/docs"
echo "   Health Check: http://localhost:8000/health"
echo "   PostgreSQL:   localhost:5432"
echo "   Redis:        localhost:6379"
echo "   OSRM:         localhost:5000"
echo ""
echo "🎨 Branding Features:"
echo "   Logo Upload:  http://localhost:8000/api/v1/branding/logo"
echo "   Get Branding: http://localhost:8000/api/v1/branding"
echo "   Logos Folder: ./uploads/logos/"
echo ""
echo "📝 Useful Commands:"
echo "   View logs:        ./logs.sh"
echo "   Stop services:    ./stop.sh"
echo "   Restart services: ./restart.sh"
echo "   Access backend:   docker compose exec backend bash"
echo ""
echo "🔍 Check migration status:"
if docker compose version &> /dev/null; then
    docker compose exec backend alembic current
else
    docker-compose exec backend alembic current
fi
echo ""
echo "✅ Ready! Open http://localhost:8000/docs to explore the API"
