#!/bin/bash
# Fix migration and deploy

echo "============================================"
echo "Fixing Migration and Deploying to Server"
echo "============================================"
echo ""

# Upload the fixed migration file
echo "[1/3] Uploading fixed migration file to server..."
scp alembic/versions/add_user_id_to_drivers.py root@fc3:/home/RR4/backend/alembic/versions/add_user_id_to_drivers.py

echo ""
echo "[2/3] Running migrations on server..."
ssh root@fc3 << 'ENDSSH'
cd /home/RR4/backend

# Run migrations
docker-compose exec -T backend alembic upgrade heads

# Verify tables
echo ""
echo "Verifying tables..."
docker-compose exec -T postgres psql -U fleet_user -d fleet_db -c "\dt" | grep public

# Seed data
echo ""
echo "Seeding default data..."
docker-compose exec -T backend python seed_capabilities.py

echo ""
echo "✅ Done!"
ENDSSH

echo ""
echo "[3/3] Testing API..."
curl -s http://34.127.125.215:8000/health | grep -q "healthy" && echo "✅ API is healthy" || echo "❌ API check failed"

echo ""
echo "============================================"
echo "✅ Deployment Complete!"
echo "============================================"
echo ""
echo "Test your app now!"
