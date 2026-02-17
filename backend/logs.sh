#!/bin/bash

# Fleet Management System - View Logs Script

echo "📋 Fleet Management System Logs"
echo "================================"
echo ""
echo "Press Ctrl+C to exit"
echo ""

# Try docker compose (new syntax) first, fallback to docker-compose
if docker compose version &> /dev/null; then
    docker compose logs -f backend
else
    docker-compose logs -f backend
fi
