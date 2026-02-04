# Production Deployment Guide

This guide covers deploying the Fleet Management System to production with security hardening, optimization, and best practices.

## 🚀 Quick Production Deployment

```bash
# 1. Copy and configure production environment
cp .env.production.example .env.production
# Edit .env.production with your secure values

# 2. Build and start production services
make prod-start

# 3. Access your application
# API: http://your-domain.com:8000
# Docs: http://your-domain.com:8000/docs
```

## 📋 Pre-Deployment Checklist

### Security Requirements

- [ ] Change all default passwords in `.env.production`
- [ ] Generate secure `SECRET_KEY` using: `openssl rand -hex 32`
- [ ] Generate `ENCRYPTION_MASTER_KEY` using: `openssl rand -base64 32`
- [ ] Generate `POSTGRES_PASSWORD` (min 20 characters, mixed case, numbers, symbols)
- [ ] Generate `REDIS_PASSWORD` (min 20 characters)
- [ ] Configure CORS origins to your actual domain only
- [ ] Enable HTTPS/SSL (use reverse proxy like Nginx)
- [ ] Set up firewall rules (only allow ports 80, 443, 22)
- [ ] Configure database backups
- [ ] Set up monitoring and alerting

### Infrastructure Requirements

**Minimum Server Specifications:**
- CPU: 2 cores
- RAM: 4GB
- Storage: 20GB SSD
- OS: Ubuntu 22.04 LTS or similar

**Recommended for Production:**
- CPU: 4+ cores
- RAM: 8GB+
- Storage: 50GB+ SSD
- OS: Ubuntu 22.04 LTS
- Separate database server (optional but recommended)

## 🔒 Security Setup

### 1. Generate Secure Credentials

```bash
# Generate SECRET_KEY
openssl rand -hex 32

# Generate ENCRYPTION_MASTER_KEY
openssl rand -base64 32

# Generate strong passwords (example)
openssl rand -base64 24
```

### 2. Configure Environment Variables

Edit `.env.production`:

```env
# Database
POSTGRES_PASSWORD=your_generated_strong_password_here

# Redis
REDIS_PASSWORD=your_generated_redis_password_here

# Application
SECRET_KEY=your_generated_secret_key_here
ENCRYPTION_MASTER_KEY=your_generated_encryption_key_here

# CORS - restrict to your domain
CORS_ORIGINS=https://yourdomain.com
```

### 3. Docker Security Best Practices

The production setup includes:

✅ **Non-root user**: Backend runs as `appuser` (UID 1001)
✅ **No new privileges**: Prevents privilege escalation
✅ **Capability dropping**: Removes unnecessary Linux capabilities
✅ **Internal networks**: Database and Redis not exposed externally
✅ **Read-only volumes**: OSRM data mounted read-only
✅ **Resource limits**: CPU and memory constraints prevent resource exhaustion
✅ **Health checks**: Automatic container restart on failure

## 🏗️ Architecture Overview

### Production Multi-Stage Build

```
┌─────────────────────────────────────────────────────┐
│ Stage 1: Base - Common dependencies                 │
│ - Python 3.11-slim                                  │
│ - Creates non-root appuser                          │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
┌───────▼─────────┐           ┌────────▼────────────┐
│ Stage 2: Builder│           │ Stage 3: Development│
│ - Build deps    │           │ - Runtime deps      │
│ - Compile pkgs  │           │ - Hot reload        │
│ - Cache layers  │           │ - Dev tools         │
└───────┬─────────┘           └─────────────────────┘
        │
┌───────▼─────────────────────┐
│ Stage 4: Production         │
│ - Minimal runtime           │
│ - No build tools            │
│ - Non-root user             │
│ - Multi-worker uvicorn      │
└─────────────────────────────┘
```

### Network Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Internet                          │
└────────────────────┬─────────────────────────────────┘
                     │
             ┌───────▼────────┐
             │  Nginx/Caddy   │ ← SSL Termination
             │  Reverse Proxy │
             └───────┬────────┘
                     │
         ┌───────────▼──────────────┐
         │   frontend network       │
         │  ┌─────────────────┐     │
         │  │   Backend:8000  │     │
         │  └────────┬────────┘     │
         └───────────┼──────────────┘
                     │
         ┌───────────▼──────────────┐
         │ backend-internal network │
         │  (No external access)    │
         │                          │
         │  ┌──────────────┐        │
         │  │ PostgreSQL   │        │
         │  └──────────────┘        │
         │                          │
         │  ┌──────────────┐        │
         │  │    Redis     │        │
         │  └──────────────┘        │
         │                          │
         │  ┌──────────────┐        │
         │  │    OSRM      │        │
         │  └──────────────┘        │
         └─────────────────────────┘
```

## 📦 Deployment Steps

### Step 1: Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose -y

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Enable Docker on boot
sudo systemctl enable docker
```

### Step 2: Application Setup

```bash
# Clone repository
git clone https://github.com/your-org/fleet-management.git
cd fleet-management/backend

# Create production environment file
cp .env.production.example .env.production

# Edit with your secure values
nano .env.production  # or vim, vi, etc.
```

### Step 3: Build and Deploy

```bash
# Build production images
make prod-build

# Start services
make prod-up

# Run migrations
make prod-db-migrate

# Verify services
docker ps
```

### Step 4: Set Up Reverse Proxy (Nginx)

Install Nginx:
```bash
sudo apt install nginx -y
```

Create Nginx config (`/etc/nginx/sites-available/fleet`):

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL certificates (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to backend
    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8000/health;
        access_log off;
    }

    # Upload limit
    client_max_body_size 10M;
}
```

Enable and restart:
```bash
sudo ln -s /etc/nginx/sites-available/fleet /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 5: SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Test renewal
sudo certbot renew --dry-run
```

## 🔍 Monitoring & Maintenance

### Health Checks

```bash
# Check all services
docker ps

# Check backend health
curl http://localhost:8000/health

# View logs
make prod-logs

# View specific service logs
docker-compose -f docker-compose.prod.yml logs backend
```

### Database Backup

```bash
# Manual backup
docker-compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U fleet_user fleet_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Automated daily backup (crontab)
0 2 * * * cd /path/to/app && docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump -U fleet_user fleet_db > /backups/db_$(date +\%Y\%m\%d).sql
```

### Log Management

```bash
# View real-time logs
make prod-logs

# Save logs to file
docker-compose -f docker-compose.prod.yml logs --since 24h > logs_$(date +%Y%m%d).txt

# Check disk usage
docker system df

# Clean old logs
docker system prune -a --volumes
```

## 🚨 Troubleshooting

### Container Won't Start

```bash
# Check logs
make prod-logs

# Check container status
docker ps -a

# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend

# Full restart
make prod-down
make prod-up
```

### Database Connection Issues

```bash
# Test database connection
docker-compose -f docker-compose.prod.yml exec backend python -c "from app.database import engine; print(engine.connect())"

# Check PostgreSQL logs
docker-compose -f docker-compose.prod.yml logs postgres

# Access database shell
docker-compose -f docker-compose.prod.yml exec postgres psql -U fleet_user -d fleet_db
```

### High Memory Usage

```bash
# Check resource usage
docker stats

# View service limits
docker-compose -f docker-compose.prod.yml config

# Restart services
make prod-restart
```

## 🔄 Updates & Deployment

### Zero-Downtime Deployment

```bash
# 1. Pull latest code
git pull origin main

# 2. Build new image
make prod-build

# 3. Apply database migrations (if any)
make prod-db-migrate

# 4. Recreate services (Docker Compose handles graceful restart)
docker-compose -f docker-compose.prod.yml up -d --force-recreate --no-deps backend

# 5. Verify
curl http://localhost:8000/health
```

### Rollback

```bash
# Checkout previous version
git checkout <previous-commit>

# Rebuild and restart
make prod-build
make prod-up
```

## 📊 Performance Optimization

### Database Connection Pool

Already configured in production:
- Pool size: 20 connections
- Max overflow: 10 connections
- Pool recycle: 1 hour

### Uvicorn Workers

Production Dockerfile uses 4 workers:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

Adjust based on CPU cores: `workers = (2 × CPU cores) + 1`

### Redis Caching

Already configured for location caching and sessions.

## 🔐 Security Hardening

### Firewall Configuration (UFW)

```bash
# Enable firewall
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check status
sudo ufw status
```

### Regular Security Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose -f docker-compose.prod.yml pull
make prod-build
make prod-up
```

### Secrets Rotation

Periodically rotate:
1. Database passwords
2. Redis password
3. SECRET_KEY
4. ENCRYPTION_MASTER_KEY
5. SSL certificates (auto-renewed by Let's Encrypt)

## 📞 Support

For issues and questions:
- Check logs: `make prod-logs`
- Review documentation: `README_DOCKER.md`
- GitHub Issues: [repository]/issues

---

**Made with ❤️ for Fleet Management System**
