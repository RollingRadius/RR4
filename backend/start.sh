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

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running!"
    echo "   Please start Docker Desktop and try again"
    exit 1
fi

echo "✅ Docker is installed and running"
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
