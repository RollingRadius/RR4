# 🔧 Docker Troubleshooting Guide

## ❌ Error: "Read timed out" or "Docker is not responding"

This error means Docker Desktop is not fully ready yet.

### Solution:

**Step 1: Check Docker Desktop is Running**

Windows:
- Look in the **system tray** (bottom right of screen)
- You should see a Docker whale icon
- Right-click it and check status
- If it says "Starting...", wait for it to finish (1-2 minutes)

Mac:
- Look in the **menu bar** (top of screen)
- Click the Docker whale icon
- Check if it shows "Docker Desktop is running"

**Step 2: Wait for Docker to Fully Start**

Docker Desktop can take 1-2 minutes to fully start. Wait until:
- The Docker icon stops animating
- Status shows "Running" or "Ready"

**Step 3: Verify Docker is Ready**

Run the check script:

**Windows:**
```bash
check-docker.bat
```

**Linux/Mac:**
```bash
./check-docker.sh
```

This will tell you if Docker is ready.

**Step 4: Try Starting Again**

Once Docker is ready, run:

**Windows:**
```bash
start.bat
```

**Linux/Mac:**
```bash
./start.sh
```

---

## 🐳 Common Issues

### Issue 1: Docker Desktop Not Installed

**Symptoms:**
- "docker: command not found"
- "Docker is not installed"

**Solution:**
Download and install Docker Desktop:
- **Windows:** https://docs.docker.com/desktop/install/windows-install/
- **Mac:** https://docs.docker.com/desktop/install/mac-install/
- **Linux:** https://docs.docker.com/desktop/install/linux-install/

---

### Issue 2: Docker Desktop Not Running

**Symptoms:**
- "Cannot connect to the Docker daemon"
- "Docker is not running"

**Solution:**
1. **Windows:** Search for "Docker Desktop" in Start Menu and run it
2. **Mac:** Open Docker Desktop from Applications
3. **Linux:** Run `sudo systemctl start docker`

Wait 1-2 minutes for Docker to start.

---

### Issue 3: Port Already in Use

**Symptoms:**
```
Error: bind: address already in use
Port 8000 is already allocated
```

**Solution:**

**Option A - Find and stop the conflicting service:**
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID_NUMBER> /F

# Linux/Mac
lsof -i :8000
kill -9 <PID>
```

**Option B - Change the port:**
Edit `docker-compose.yml`:
```yaml
backend:
  ports:
    - "8001:8000"  # Changed from 8000 to 8001
```

Then access at: http://localhost:8001

---

### Issue 4: Not Enough Resources

**Symptoms:**
- Services crash or restart
- "Out of memory" errors
- Very slow startup

**Solution:**

Increase Docker resources:

1. Open Docker Desktop
2. Go to **Settings** → **Resources**
3. Increase:
   - **CPUs:** At least 2
   - **Memory:** At least 4GB
   - **Disk:** At least 20GB
4. Click **Apply & Restart**

---

### Issue 5: Migration Errors

**Symptoms:**
```
alembic.util.exc.CommandError: Multiple head revisions
```

**Solution:**

Check migration status:
```bash
docker compose exec backend alembic current
docker compose exec backend alembic heads
```

If you see multiple heads, the migrations will be applied automatically on next restart.

---

### Issue 6: Permission Denied (Linux/Mac)

**Symptoms:**
```
Permission denied: './start.sh'
```

**Solution:**
```bash
chmod +x *.sh
./start.sh
```

---

### Issue 7: Logo Upload Fails

**Symptoms:**
- 500 error when uploading logo
- "Permission denied" in logs

**Solution:**

Fix uploads directory permissions:
```bash
# Create directory if missing
mkdir -p uploads/logos

# Fix permissions
docker compose exec backend chown -R appuser:appgroup /app/uploads
docker compose exec backend chmod -R 755 /app/uploads

# Restart backend
docker compose restart backend
```

---

### Issue 8: Database Connection Failed

**Symptoms:**
```
sqlalchemy.exc.OperationalError
Connection refused (postgres:5432)
```

**Solution:**

Check PostgreSQL is healthy:
```bash
docker compose ps postgres
```

Should show "Up (healthy)".

If not:
```bash
# Restart database
docker compose restart postgres

# Wait 10 seconds
sleep 10

# Check logs
docker compose logs postgres
```

---

### Issue 9: Services Start but Backend Crashes

**Symptoms:**
- Backend shows "Restarting" or "Unhealthy"

**Solution:**

Check backend logs:
```bash
docker compose logs backend
```

Common causes:
- Missing environment variables
- Database not ready
- Port conflict

Try:
```bash
# Restart services in order
docker compose down
docker compose up -d postgres redis
sleep 10
docker compose up -d backend
```

---

### Issue 10: Complete Reset Needed

**When to use:**
- Nothing else works
- Want to start fresh

**WARNING: This deletes ALL data!**

```bash
# Windows
docker compose down -v
rmdir /s /q uploads logs
start.bat

# Linux/Mac
docker compose down -v
rm -rf uploads logs
./start.sh
```

---

## 📊 Diagnostic Commands

### Check Everything
```bash
# Windows
check-docker.bat
status.bat

# Linux/Mac
./check-docker.sh
./status.sh
```

### View Logs
```bash
# All services
docker compose logs

# Backend only
docker compose logs backend

# Follow logs (live)
docker compose logs -f backend

# Last 100 lines
docker compose logs --tail=100 backend
```

### Check Service Health
```bash
# List all services
docker compose ps

# Check specific service
docker compose ps backend

# Check if healthy
curl http://localhost:8000/health
```

### Access Container
```bash
# Backend shell
docker compose exec backend bash

# Database shell
docker compose exec postgres psql -U fleet_user -d fleet_db

# Redis shell
docker compose exec redis redis-cli
```

---

## 🆘 Still Having Issues?

1. **Check Docker logs:**
   ```bash
   docker compose logs
   ```

2. **Check system resources:**
   - Docker Desktop → Settings → Resources
   - Ensure enough CPU, RAM, Disk

3. **Restart Docker Desktop:**
   - Quit Docker Desktop completely
   - Start it again
   - Wait 2 minutes
   - Try `./start.sh` again

4. **Update Docker Desktop:**
   - Download latest version
   - Install and restart

5. **Check documentation:**
   - Read `DOCKER_README.md`
   - Check `docker-compose.yml` configuration

---

## ✅ Quick Checklist

Before running `start.sh`:

- [ ] Docker Desktop is installed
- [ ] Docker Desktop is running (check system tray/menu bar)
- [ ] Docker status shows "Running" (not "Starting...")
- [ ] `check-docker.bat` or `./check-docker.sh` shows "Docker is ready"
- [ ] Ports 8000, 5432, 6379, 5000 are not in use
- [ ] At least 4GB RAM allocated to Docker
- [ ] At least 2 CPUs allocated to Docker

Once all checked, run:
```bash
./start.sh     # Linux/Mac
start.bat      # Windows
```

---

## 🎯 Success Indicators

When everything works, you should see:

```bash
✅ Docker is ready!
✅ Directories created
✅ Services started
✅ All services "Up (healthy)"
✅ Backend health check passes
✅ Migration 012 applied
✅ Ready! Open http://localhost:8000/docs
```

---

Need more help? Check the logs:
```bash
docker compose logs -f
```
