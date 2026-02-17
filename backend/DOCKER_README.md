# 🐳 Docker Setup - Fleet Management System

## 🚀 Quick Start

### Windows
```bash
start.bat
```

### Linux/Mac
```bash
./start.sh
```

That's it! All services will start automatically.

---

## 📋 What You Get

When you run the start script, you get:

✅ **PostgreSQL** (port 5432) - Database with auto-migrations
✅ **Redis** (port 6379) - Cache for sessions
✅ **Backend API** (port 8000) - FastAPI with hot-reload
✅ **OSRM** (port 5000) - Routing service

Plus all **white-label branding features**:
- Logo upload endpoint
- Color customization API
- Static file serving for logos
- Automatic branding table creation

---

## 📂 Directory Structure

```
backend/
├── start.sh / start.bat          ← START HERE (your OS)
├── stop.sh / stop.bat             ← Stop services
├── logs.sh / logs.bat             ← View logs
├── restart.sh / restart.bat       ← Restart services
├── status.sh / status.bat         ← Check status
├── docker-compose.yml             ← Service configuration
├── Dockerfile                     ← Backend image
├── docker-entrypoint.sh           ← Startup script
├── .env.docker                    ← Environment variables
├── uploads/                       ← Logo storage (auto-created)
│   └── logos/
│       └── {org_id}/
└── logs/                         ← Application logs
```

---

## 🎯 Available Scripts

| Script | Windows | Linux/Mac | Description |
|--------|---------|-----------|-------------|
| **Start** | `start.bat` | `./start.sh` | Start all services |
| **Stop** | `stop.bat` | `./stop.sh` | Stop all services |
| **Logs** | `logs.bat` | `./logs.sh` | View backend logs |
| **Restart** | `restart.bat` | `./restart.sh` | Restart services |
| **Status** | `status.bat` | `./status.sh` | Check service status |

---

## 🔍 Verify Installation

After running `start.bat` or `./start.sh`:

1. **Check services are running:**
   ```bash
   docker compose ps
   ```
   All should show "Up" and "healthy"

2. **Test backend API:**
   ```bash
   curl http://localhost:8000/health
   ```
   Should return: `{"status":"healthy",...}`

3. **View API documentation:**
   Open http://localhost:8000/docs in your browser

4. **Check branding endpoints:**
   Look for `/api/v1/branding` in Swagger docs

---

## 🎨 Test Branding Features

### 1. Get Default Branding
```bash
# You'll need an auth token first
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/v1/branding
```

### 2. Update Colors
```bash
curl -X PUT http://localhost:8000/api/v1/branding \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "colors": {
      "primary_color": "#FF5733",
      "primary_dark": "#C70039",
      "primary_light": "#FF8D7D"
    }
  }'
```

### 3. Upload Logo
```bash
curl -X POST http://localhost:8000/api/v1/branding/logo \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@path/to/logo.png"
```

### 4. Access Logo
```
http://localhost:8000/uploads/logos/{org_id}/{filename}
```

---

## 🔧 Common Tasks

### View Logs
**Windows:** `logs.bat`
**Linux/Mac:** `./logs.sh`

### Restart After Code Changes
**Windows:** `restart.bat`
**Linux/Mac:** `./restart.sh`

### Access Database
```bash
docker compose exec postgres psql -U fleet_user -d fleet_db
```

### Run Migrations Manually
```bash
docker compose exec backend alembic upgrade head
```

### Access Backend Shell
```bash
docker compose exec backend bash
```

### Check Migration Status
```bash
docker compose exec backend alembic current
```

---

## 🛠️ Troubleshooting

### Services won't start
```bash
# Check Docker is running
docker info

# View detailed logs
docker compose logs

# Rebuild everything
docker compose down
docker compose up -d --build
```

### Port already in use
Edit `docker-compose.yml` and change the port:
```yaml
ports:
  - "8001:8000"  # Changed from 8000
```

### Database errors
```bash
# Reset database (WARNING: Deletes all data!)
docker compose down -v
docker compose up -d
```

### Logo upload not working
```bash
# Check uploads directory
ls -la uploads/logos

# Fix permissions
docker compose exec backend chown -R appuser:appgroup /app/uploads
```

---

## 🌐 Connect Frontend

Your Flutter app should already be configured:

```dart
// frontend/lib/core/config/app_config.dart
static const String apiBaseUrl = 'http://localhost:8000';
```

Start the frontend:
```bash
cd frontend
flutter pub get
flutter run
```

Then navigate to Settings → Branding to test!

---

## 📊 Database Info

- **Database:** fleet_db
- **User:** fleet_user
- **Password:** fleet_password_2024
- **Host:** localhost
- **Port:** 5432

Connection string:
```
postgresql://fleet_user:fleet_password_2024@localhost:5432/fleet_db
```

---

## 🔐 Production Deployment

For production, use the production compose file:

```bash
docker compose -f docker-compose.prod.yml up -d
```

Differences:
- Multi-worker Uvicorn (4 workers)
- Non-root user for security
- No hot-reload (better performance)
- Optimized image size

---

## 📦 Data Persistence

All data is saved in Docker volumes:
- `fleet_postgres_data` - Database
- `fleet_redis_data` - Redis cache
- `./uploads` - Logos (mapped to host)
- `./logs` - Logs (mapped to host)

To backup:
```bash
docker compose exec postgres pg_dump -U fleet_user fleet_db > backup.sql
```

To restore:
```bash
cat backup.sql | docker compose exec -T postgres psql -U fleet_user fleet_db
```

---

## ✅ Success Checklist

After running start script:

- [ ] All 4 services show "Up (healthy)" in `docker compose ps`
- [ ] Can access http://localhost:8000/docs
- [ ] Health endpoint returns success
- [ ] Can see branding endpoints in Swagger
- [ ] `alembic current` shows migration 012
- [ ] Frontend can connect successfully

---

## 🎉 You're Ready!

Your Docker backend is now running with:
- ✅ All services healthy
- ✅ Automatic migrations
- ✅ Logo upload support
- ✅ Branding API endpoints
- ✅ Hot-reload for development

**Next Steps:**
1. Login to get an auth token
2. Test branding endpoints
3. Upload a logo
4. Connect your Flutter frontend
5. Customize your branding!

---

## 📞 Need Help?

**View logs:** `logs.bat` or `./logs.sh`
**Check status:** `docker compose ps`
**Restart:** `restart.bat` or `./restart.sh`

**Common endpoints:**
- API Docs: http://localhost:8000/docs
- Health: http://localhost:8000/health
- Branding: http://localhost:8000/api/v1/branding
