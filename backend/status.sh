#!/bin/bash

# Fleet Management System - Status Check Script

echo "📊 Fleet Management System - Status"
echo "===================================="
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running!"
    exit 1
fi

# Check service status
echo "🐳 Docker Services:"
echo ""
if docker compose version &> /dev/null; then
    docker compose ps
else
    docker-compose ps
fi

echo ""
echo "🔍 Backend Health:"
curl -s http://localhost:8000/health | jq '.' 2>/dev/null || curl -s http://localhost:8000/health || echo "❌ Backend not responding"

echo ""
echo "💾 Database Migration Status:"
if docker compose version &> /dev/null; then
    docker compose exec backend alembic current 2>/dev/null || echo "❌ Cannot connect to backend"
else
    docker-compose exec backend alembic current 2>/dev/null || echo "❌ Cannot connect to backend"
fi

echo ""
echo "📁 Uploads Directory:"
ls -lh uploads/logos/ 2>/dev/null || echo "   (empty)"

echo ""
echo "📊 Docker Volumes:"
docker volume ls | grep fleet || echo "   No volumes found"
