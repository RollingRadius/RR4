#!/bin/bash

# Docker Readiness Check Script

echo "🔍 Docker Readiness Check"
echo "========================="
echo ""

# Check if Docker command exists
if ! command -v docker &> /dev/null; then
    echo "❌ Docker command not found!"
    echo "   Please install Docker Desktop"
    exit 1
fi

echo "✅ Docker command found"
echo ""

# Check Docker daemon
echo "Checking Docker daemon..."
if docker info &> /dev/null; then
    echo "✅ Docker daemon is running"
    echo ""

    # Show Docker version
    echo "Docker version:"
    docker --version
    echo ""

    # Show Docker info
    echo "Docker info:"
    docker info | grep -E "Server Version|Operating System|Total Memory|CPUs"
    echo ""

    # Check if compose is available
    if docker compose version &> /dev/null; then
        echo "✅ Docker Compose available"
        docker compose version
    elif docker-compose version &> /dev/null; then
        echo "✅ Docker Compose available (legacy)"
        docker-compose version
    else
        echo "⚠️  Docker Compose not found"
    fi
    echo ""

    # Check running containers
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep fleet || echo "   (none)"
    echo ""

    echo "✅ Docker is ready to use!"
    echo ""
    echo "You can now run: ./start.sh"
else
    echo "❌ Docker daemon is not running"
    echo ""
    echo "Please:"
    echo "  1. Start Docker Desktop"
    echo "  2. Wait for Docker to fully start (1-2 minutes)"
    echo "  3. Run this script again to verify"
    echo ""
    echo "On Windows:"
    echo "  - Look for Docker icon in system tray"
    echo "  - Right-click and ensure Docker Desktop is running"
    echo ""
    echo "On Mac:"
    echo "  - Look for Docker icon in menu bar"
    echo "  - Click and check status"
fi
