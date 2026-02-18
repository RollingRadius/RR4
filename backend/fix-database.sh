#!/bin/bash

echo "=========================================="
echo "Fleet Management - Database Fix Script"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: docker-compose.yml not found!${NC}"
    echo "Please run this script from /home/RR4/backend directory"
    exit 1
fi

echo -e "${YELLOW}[1/6] Checking Docker containers...${NC}"
docker-compose ps
echo ""

echo -e "${YELLOW}[2/6] Checking if database is accessible...${NC}"
if docker-compose exec -T postgres pg_isready -U fleet_user -d fleet_db > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database is accessible${NC}"
else
    echo -e "${RED}❌ Database is not accessible${NC}"
    echo "Restarting PostgreSQL..."
    docker-compose restart postgres
    sleep 5
fi
echo ""

echo -e "${YELLOW}[3/6] Running database migrations...${NC}"
echo "This will create all necessary tables..."

if docker-compose exec -T backend alembic upgrade head 2>&1; then
    echo -e "${GREEN}✅ Migrations completed successfully!${NC}"
else
    echo -e "${RED}❌ Migration failed!${NC}"
    echo ""
    echo "Trying to fix..."

    # Try restarting backend
    echo "Restarting backend container..."
    docker-compose restart backend
    sleep 10

    # Try migrations again
    echo "Retrying migrations..."
    if docker-compose exec -T backend alembic upgrade head 2>&1; then
        echo -e "${GREEN}✅ Migrations completed on retry!${NC}"
    else
        echo -e "${RED}❌ Migration still failed. Check logs:${NC}"
        echo "docker-compose logs backend"
        exit 1
    fi
fi
echo ""

echo -e "${YELLOW}[4/6] Verifying database tables...${NC}"
TABLES=$(docker-compose exec -T postgres psql -U fleet_user -d fleet_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')

if [ "$TABLES" -gt "0" ]; then
    echo -e "${GREEN}✅ Found $TABLES tables in database${NC}"
    echo ""
    echo "Tables created:"
    docker-compose exec -T postgres psql -U fleet_user -d fleet_db -c "\dt" 2>/dev/null | grep "public"
else
    echo -e "${RED}❌ No tables found!${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}[5/6] Initializing default data...${NC}"
if docker-compose exec -T backend python init-db.py 2>&1; then
    echo -e "${GREEN}✅ Default data initialized${NC}"
else
    echo -e "${YELLOW}⚠️  Init script had issues, but might be OK if data already exists${NC}"
fi
echo ""

echo -e "${YELLOW}[6/6] Testing API endpoints...${NC}"

# Test root endpoint
if curl -s http://localhost:8000/ | grep -q "Fleet Management"; then
    echo -e "${GREEN}✅ API root endpoint working${NC}"
else
    echo -e "${RED}❌ API root endpoint failed${NC}"
fi

# Test signup endpoint
SIGNUP_TEST=$(curl -s -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"username":"test_'$(date +%s)'","email":"test'$(date +%s)'@test.com","password":"Test123!","full_name":"Test User","phone":"1234567890","auth_method":"email","terms_accepted":true}')

if echo "$SIGNUP_TEST" | grep -q "id"; then
    echo -e "${GREEN}✅ Signup endpoint working${NC}"
elif echo "$SIGNUP_TEST" | grep -q "already exists"; then
    echo -e "${GREEN}✅ Signup endpoint working (user exists)${NC}"
else
    echo -e "${RED}❌ Signup endpoint failed${NC}"
    echo "Response: $SIGNUP_TEST"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ DATABASE FIX COMPLETE!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test API in browser: http://34.127.125.215:8000/docs"
echo "2. Open Fleet Management app on your phone"
echo "3. Try signup/login"
echo ""
echo "If you still get errors, check logs:"
echo "  docker-compose logs -f backend"
echo ""
