# Windows Quick Start Guide

## 🚀 One-Click Startup

Simply **double-click** `start.bat` in the backend folder!

That's it! The script will:
- ✅ Check if Docker is installed
- ✅ Start Docker Desktop if needed
- ✅ Build all images
- ✅ Start all services (PostgreSQL, Redis, OSRM, Backend)
- ✅ Run database migrations
- ✅ Open API documentation in your browser

## 📁 Available Batch Files

All these files are in the `backend` folder. Just double-click to run:

### Main Commands

| File | Description | What it does |
|------|-------------|--------------|
| **start.bat** | Start everything | Builds and starts all Docker services |
| **stop.bat** | Stop services | Stops all running containers |
| **restart.bat** | Restart services | Quick restart without rebuilding |
| **logs.bat** | View logs | Shows live logs from all services |

### Advanced Commands

| File | Description |
|------|-------------|
| **start-prod.bat** | Start production environment |
| **shell.bat** | Open backend container shell |
| **db-shell.bat** | Open PostgreSQL shell |
| **reset-db.bat** | Reset database (DELETE ALL DATA) |

## 🎯 Common Workflows

### First Time Setup

1. **Install Docker Desktop**
   - Download from: https://www.docker.com/products/docker-desktop
   - Install and restart computer
   - Open Docker Desktop (wait for it to start)

2. **Start the application**
   ```
   Double-click: start.bat
   ```

3. **Access the API**
   - Automatically opens in browser: http://localhost:8000/docs
   - Or visit manually: http://localhost:8000

### Daily Development

```
1. Double-click: start.bat
2. Edit your code (auto-reloads)
3. Double-click: logs.bat (to watch what's happening)
4. Double-click: stop.bat (when done)
```

### Reset Database

```
Double-click: reset-db.bat
(This will DELETE ALL DATA!)
```

### View Live Logs

```
Double-click: logs.bat
(Press Ctrl+C to stop viewing)
```

## 🔧 What Each Script Does

### start.bat - Main Startup Script

**What it does:**
1. Checks if Docker is installed
2. Starts Docker Desktop if not running
3. Stops any running containers
4. Builds Docker images (uses cache, so it's fast after first time)
5. Starts all services:
   - PostgreSQL database
   - Redis cache
   - OSRM routing service
   - Backend API
6. Runs database migrations automatically
7. Tests backend health
8. Opens API docs in browser

**When to use:**
- First time setup
- After pulling new code
- After changing Dockerfile or requirements.txt
- When containers are not running

**Output:**
```
========================================
Fleet Management System - Docker Setup
========================================

[INFO] Docker is running
Docker version 24.0.x
...

========================================
Application Started Successfully!
========================================

Backend API:  http://localhost:8000
API Docs:     http://localhost:8000/docs
...
```

### stop.bat - Stop All Services

**What it does:**
- Stops all running containers
- Networks are removed
- Volumes (data) are kept

**When to use:**
- End of work day
- Before shutting down computer
- Before switching to production mode
- When you need to free up resources

### logs.bat - View Live Logs

**What it does:**
- Shows real-time logs from all containers
- Color-coded by service
- Updates live as things happen

**When to use:**
- Debugging issues
- Watching API requests
- Monitoring database queries
- Checking for errors

**How to use:**
1. Double-click `logs.bat`
2. Watch the output
3. Press `Ctrl+C` to stop

### restart.bat - Quick Restart

**What it does:**
- Restarts all containers without rebuilding
- Faster than stop + start

**When to use:**
- Services are running but not responding
- After changing .env.docker file
- Quick refresh without full rebuild

### start-prod.bat - Production Mode

**What it does:**
1. Checks for `.env.production` file
2. Confirms you want to start production
3. Builds optimized production images
4. Starts with production configuration
5. Uses security hardening

**When to use:**
- Testing production build locally
- Before deploying to server
- Checking production configuration

**Requirements:**
- Must create `.env.production` first
- Must have secure passwords configured

### shell.bat - Backend Shell

**What it does:**
- Opens bash shell inside backend container
- Gives you command line access
- Can run Python, pip, alembic commands

**When to use:**
- Running custom database queries
- Installing additional packages (testing)
- Debugging Python code
- Manual operations

**Example commands inside shell:**
```bash
python                          # Start Python
alembic history                 # View migration history
ls -la /app                     # List files
pip list                        # Show installed packages
exit                            # Leave shell
```

### db-shell.bat - Database Shell

**What it does:**
- Opens PostgreSQL psql shell
- Direct database access
- Can run SQL queries

**When to use:**
- Inspecting database tables
- Running SQL queries
- Checking data
- Database debugging

**Example commands:**
```sql
\dt                             -- List tables
\d users                        -- Describe users table
SELECT * FROM users;            -- Query users
\q                              -- Quit
```

## 🌐 Service URLs

After starting with `start.bat`, access:

| Service | URL | Description |
|---------|-----|-------------|
| **API Documentation** | http://localhost:8000/docs | Interactive API docs (Swagger) |
| **Backend API** | http://localhost:8000 | Main API endpoint |
| **Health Check** | http://localhost:8000/health | Server health status |
| **PostgreSQL** | localhost:5432 | Database (use pgAdmin or similar) |
| **Redis** | localhost:6379 | Cache (use Redis Desktop Manager) |

## ⚙️ Configuration Files

| File | Purpose | Edit? |
|------|---------|-------|
| `.env.docker` | Development environment | ✅ Yes (for dev) |
| `.env.production` | Production environment | ✅ Yes (create from example) |
| `docker-compose.yml` | Development services | ⚠️ Careful |
| `docker-compose.prod.yml` | Production services | ⚠️ Careful |
| `Dockerfile` | Container definition | ⚠️ Advanced |

## 🐛 Troubleshooting

### "Docker is not installed"

**Solution:**
1. Install Docker Desktop: https://www.docker.com/products/docker-desktop
2. Restart computer
3. Start Docker Desktop application
4. Wait for it to show "Docker Desktop is running"
5. Run `start.bat` again

### "Port is already in use"

**Problem:** Another program is using port 8000, 5432, or 6379

**Solution:**
```cmd
REM Find what's using the port
netstat -ano | findstr :8000

REM Stop the other program or container
docker ps
docker stop <container_name>
```

### Services start but backend returns 502

**Problem:** Backend is still starting up

**Solution:**
- Wait 30 seconds
- Check logs: Double-click `logs.bat`
- Look for "Application startup complete" message
- Refresh browser

### "Cannot connect to database"

**Problem:** PostgreSQL not ready

**Solution:**
1. Double-click `logs.bat`
2. Look for PostgreSQL logs
3. Wait for "database system is ready to accept connections"
4. Try again

### Build takes forever

**Problem:** First build downloads everything

**Solution:**
- First build can take 5-10 minutes
- Subsequent builds use cache (much faster)
- Be patient on first run
- Good internet connection helps

### Docker Desktop won't start

**Solution:**
1. Check if WSL2 is installed (required)
2. Open Windows Features
3. Enable "Virtual Machine Platform"
4. Enable "Windows Subsystem for Linux"
5. Restart computer
6. Update Docker Desktop to latest version

## 💡 Pro Tips

1. **Keep logs open while developing**
   - Double-click `logs.bat`
   - Leave it running in a separate window
   - You'll see errors immediately

2. **Use start.bat every morning**
   - It's smart and fast (uses cached builds)
   - Ensures everything is up-to-date
   - Runs migrations automatically

3. **Don't manually edit the database**
   - Use `reset-db.bat` to reset
   - Use migrations for schema changes
   - Backup before major operations

4. **Check health endpoint**
   - Visit: http://localhost:8000/health
   - Should return: `{"status": "healthy"}`
   - If not, check logs

5. **Stop services when not using**
   - Double-click `stop.bat`
   - Frees up computer resources
   - Data is preserved in Docker volumes

## 📊 Resource Usage

Typical usage on Windows:
- **CPU**: 10-20% idle, 30-50% under load
- **Memory**: ~2-3GB total
- **Disk**: ~5GB for images and volumes

If your computer is slow:
- Close other applications
- Increase Docker Desktop memory limit (Settings → Resources)
- Use `stop.bat` when not developing

## 🔄 Update Workflow

When you pull new code from git:

```
1. Stop services:    stop.bat
2. Pull new code:    git pull
3. Start fresh:      start.bat
```

The script will rebuild automatically if needed.

## 🆘 Need Help?

**Check logs first:**
```
Double-click: logs.bat
```

**Common commands:**
```cmd
REM View running containers
docker ps

REM View all containers (including stopped)
docker ps -a

REM Check Docker version
docker --version

REM Check Docker is running
docker info
```

**Full cleanup (last resort):**
```cmd
docker-compose down -v
docker system prune -a
```
Then run `start.bat` again.

## 📚 Documentation

- **DOCKER_QUICKSTART.md** - This file
- **README_DOCKER.md** - Detailed Docker documentation
- **PRODUCTION_DEPLOYMENT.md** - Production setup
- **DOCKER_IMPROVEMENTS.md** - Technical details

---

**Made with ❤️ for Fleet Management System**

**Windows Quick Start** - Just double-click and go! 🚀
