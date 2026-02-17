#!/bin/bash

# Fleet Management System - Docker Stop Script

echo "🛑 Stopping Fleet Management System..."
echo ""

# Try docker compose (new syntax) first, fallback to docker-compose
if docker compose version &> /dev/null; then
    docker compose down
else
    docker-compose down
fi

echo ""
echo "✅ All services stopped"
echo ""
echo "💡 Data is preserved in Docker volumes"
echo "   To remove all data, run: docker compose down -v"
