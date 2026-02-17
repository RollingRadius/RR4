#!/bin/bash

# Fleet Management System - Docker Restart Script

echo "🔄 Restarting Fleet Management System..."
echo ""

# Try docker compose (new syntax) first, fallback to docker-compose
if docker compose version &> /dev/null; then
    docker compose restart
else
    docker-compose restart
fi

echo ""
echo "✅ Services restarted"
echo ""
echo "📊 Service Status:"
if docker compose version &> /dev/null; then
    docker compose ps
else
    docker-compose ps
fi
