# DevOps & Observability Roadmap
> Fleet Management System — RR4 Project
> Covers: SigNoz, Prometheus, Grafana, OpenTelemetry, CI/CD Pipelines, Docker, Kubernetes, Branch Strategy, Feature Flags, Quality Gates

---

## Current State of the Project (Baseline)

- **Backend:** FastAPI + SQLAlchemy + Redis + PostgreSQL
- **Frontend:** Flutter mobile app
- **Docker:** Multi-stage Dockerfile (dev + production targets) + docker-compose.yml
- **Branch:** Only `main` exists
- **Monitoring:** SigNoz installed and running locally
- **Pipeline:** None yet
- **Server:** Local only, no staging/production server yet

---

## Phase Overview

```
Phase 1  →  OpenTelemetry + SigNoz (local observability)
Phase 2  →  Git branch strategy + PR protection rules
Phase 3  →  CI Pipeline (lint + tests on every PR)
Phase 4  →  CD Pipeline (auto-deploy to staging)
Phase 5  →  Prometheus + Grafana (metrics layer)
Phase 6  →  Quality Gates (APM-driven deploy decisions)
Phase 7  →  Kubernetes (when scaling is needed)
```

---

## Phase 1 — OpenTelemetry + SigNoz

### 1.1 What SigNoz Does
- **Role:** Distributed tracing + APM (Application Performance Monitoring)
- **Sees:** Which API endpoints are slow, DB query times, Redis call times, error traces, request flows
- **Local dashboard:** `http://localhost:3301`
- **Receives traces via:** OTLP protocol on port `4317` (gRPC) or `4318` (HTTP)

### 1.2 Correct Packages to Install

Remove Flask (not used). Match packages to your actual stack:

```bash
pip install \
  opentelemetry-sdk \
  opentelemetry-api \
  opentelemetry-exporter-otlp-proto-grpc \
  opentelemetry-instrumentation-fastapi \
  opentelemetry-instrumentation-sqlalchemy \
  opentelemetry-instrumentation-redis \
  opentelemetry-instrumentation-requests
```

Add to `requirements.txt`:
```
opentelemetry-sdk>=1.20.0
opentelemetry-api>=1.20.0
opentelemetry-exporter-otlp-proto-grpc>=1.20.0
opentelemetry-instrumentation-fastapi>=0.41b0
opentelemetry-instrumentation-sqlalchemy>=0.41b0
opentelemetry-instrumentation-redis>=0.41b0
opentelemetry-instrumentation-requests>=0.41b0
```

### 1.3 Implementation Plan (3 files to touch)

**File 1 — `app/telemetry.py` (new file, isolated module)**
- Creates TracerProvider with service name
- Points OTLP exporter to SigNoz (`http://localhost:4317`)
- Instruments FastAPI, SQLAlchemy engine, Redis, Requests
- If deleted later — zero residue in the rest of the codebase

**File 2 — `app/config.py` (add 2 fields)**
```python
OTEL_ENABLED: bool = False
OTEL_ENDPOINT: str = "http://localhost:4317"
OTEL_SERVICE_NAME: str = "fleet-management-api"
```

**File 3 — `app/main.py` (add 3 lines after `app = FastAPI(...)`)**
```python
if settings.OTEL_ENABLED:
    from app.telemetry import setup_telemetry
    from app.database import engine
    setup_telemetry(app, engine=engine, otlp_endpoint=settings.OTEL_ENDPOINT)
```

### 1.4 Feature Flag Design

The entire OTEL integration is controlled by one env var in `.env`:

```env
OTEL_ENABLED=true    # turn on — traces appear in SigNoz
OTEL_ENABLED=false   # turn off — zero overhead, nothing runs, no imports
```

**Why this is a proper feature flag:**
- `telemetry.py` is only imported when `OTEL_ENABLED=true`
- No packages load when disabled
- To **disable:** set `OTEL_ENABLED=false`, restart
- To **fully remove:** delete `telemetry.py`, remove the 3 lines in `main.py`, remove 2 config vars, uninstall packages — clean slate

### 1.5 Running SigNoz Locally

```bash
# Step 1: Start SigNoz stack (Docker required)
cd signoz/deploy
docker compose up -d
# SigNoz listens on localhost:4317 (OTLP)
# Dashboard at localhost:3301

# Step 2: Start your app with OTEL enabled
# In backend/.env:
OTEL_ENABLED=true
OTEL_ENDPOINT=http://localhost:4317

# Run app directly (outside Docker, simplest for local dev)
uvicorn app.main:app --reload

# Step 3: Make some API calls, then open localhost:3301 to see traces
```

**Note:** If running app inside Docker too, SigNoz and your app need to share a Docker network,
or use `host.docker.internal:4317` as the OTEL endpoint from inside containers.

### 1.6 What SigNoz Shows You (per your stack)
- Every HTTP request: method, route, status code, duration
- Every SQL query: the actual query, duration, which endpoint triggered it
- Every Redis call: command, duration
- Every outbound HTTP call (requests lib): URL, duration
- Error traces: full stack trace, which span failed, context

---

## Phase 2 — Git Branch Strategy

### 2.1 Branch Structure

```
main          ← production only. protected. no direct pushes ever.
staging       ← pre-prod. mirrors prod environment. QA happens here.
develop       ← integration branch. all features merge here first.
feature/*     ← one branch per feature  (e.g. feature/otel-tracing)
fix/*         ← bug fixes               (e.g. fix/redis-timeout)
hotfix/*      ← critical prod fixes that skip develop/staging flow
```

### 2.2 Creating Missing Branches

```bash
git checkout -b develop
git push -u origin develop

git checkout -b staging
git push -u origin staging

git checkout main
```

### 2.3 PR Flow (after branches exist)

```
feature/xyz  →  PR into develop   (CI runs, 1 approval)
develop      →  PR into staging   (full tests, auto-deploys to staging)
staging      →  PR into main      (manual approval + all checks pass → prod deploy)

hotfix/xyz   →  PR into main AND develop simultaneously
```

### 2.4 Branch Protection Rules on GitHub

Path: `Repo → Settings → Branches → Add rule` (classic) or `Add ruleset` (new UI)

**For `main` and `staging`:**
| Setting | Value |
|---------|-------|
| Require pull request before merging | ON |
| Required approvals | 1 |
| Require status checks to pass | ON (add CI job names once pipeline exists) |
| Require branch up to date before merge | ON |
| Allow force pushes | OFF |
| Allow deletions | OFF |

**For `develop`:**
| Setting | Value |
|---------|-------|
| Require pull request | ON |
| Required approvals | 1 (or 0 if solo dev) |
| Allow force pushes | OFF |

**Solo developer tip:** On the ruleset, enable "Allow specified actors to bypass" and add yourself.
Keeps protection for others while letting you merge when needed.

### 2.5 Feature Flags (Two Levels)

**Level 1 — Env var flags** (for infrastructure/integrations, needs restart)
```env
OTEL_ENABLED=false
NEW_NOTIFICATION_ENGINE=false
GPS_LIVE_TRACKING_V2=false
```

**Level 2 — DB/Redis runtime flags** (for business features, instant toggle, no restart)
```sql
CREATE TABLE feature_flags (
  name VARCHAR PRIMARY KEY,
  enabled BOOLEAN DEFAULT false,
  description TEXT,
  updated_at TIMESTAMP
);
```
API reads flag at request time. Flip a row = feature on/off instantly.

---

## Phase 3 — CI Pipeline (GitHub Actions)

### 3.1 File Structure to Create

```
.github/
  workflows/
    ci.yml           ← runs on every PR (lint, test, build)
    cd-staging.yml   ← runs when develop merges
    cd-prod.yml      ← runs when staging merges to main

scripts/
  quality_gate.py    ← queries Prometheus + SigNoz after deploy
  smoke_test.py      ← real HTTP calls to staging after deploy
  rollback.py        ← called if quality gate fails
```

### 3.2 How the Pipeline Works

GitHub spins up a **fresh Ubuntu machine (runner)** for every pipeline run:
1. Clones your repo
2. Executes `.yml` instructions top to bottom
3. Reports pass/fail back to the PR
4. Destroys the machine — nothing carries over

The pipeline runs the **exact same commands you run locally**, just automated on that clean machine.

### 3.3 CI Pipeline Steps (`ci.yml`)

```
Trigger: every PR opened or updated

Steps:
  1. Checkout code
  2. Set up Python 3.11
  3. Start services (Postgres 15 + Redis 7 as Docker containers — real, not mocked)
  4. pip install -r requirements.txt
  5. alembic upgrade head  (run your actual migrations on test DB)
  6. ruff check app/       (linting)
  7. pytest tests/         (unit + integration tests against real DB)
  8. docker build --target production  (verify image builds clean)
  9. trivy scan image       (CVE security scan)

Result: PR shows green (can merge) or red (blocked)
```

### 3.4 Test Layers

**Layer 1 — Unit tests** (no DB, milliseconds)
```python
# tests/unit/test_security.py
def test_password_hashing():
def test_jwt_token_creation():
def test_permission_check():
```

**Layer 2 — Integration tests** (real DB + Redis, full request cycle)
```python
# tests/integration/test_auth.py
def test_register_and_login(client, db):
    # hits real Postgres, real endpoints

# tests/integration/test_trips.py
def test_create_trip_requires_driver(client, db):
```

**Layer 3 — Smoke tests** (after staging deploy, real HTTP calls)
```python
# scripts/smoke_test.py
def test_health():    requests.get(f"{STAGING}/health")
def test_auth_reachable(): requests.post(f"{STAGING}/api/auth/login", ...)
```

### 3.5 Trace-Aware Tests (OpenTelemetry in pytest)

Using `InMemorySpanExporter` — no external services needed, runs in CI:

```python
# tests/conftest.py
@pytest.fixture
def span_exporter():
    from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter
    exporter = InMemorySpanExporter()
    # wire into tracer provider
    yield exporter

# tests/integration/test_trips.py
def test_no_n_plus_one_queries(client, db, span_exporter):
    client.get("/api/trips")
    db_spans = [s for s in span_exporter.get_finished_spans() if "SELECT" in s.name]
    assert len(db_spans) < 5  # catch N+1 bugs

def test_no_error_spans(client, db, span_exporter):
    client.post("/api/auth/login", json={...})
    from opentelemetry.trace import StatusCode
    errors = [s for s in span_exporter.get_finished_spans()
              if s.status.status_code == StatusCode.ERROR]
    assert len(errors) == 0

def test_endpoint_not_slow(client, db, span_exporter):
    client.get("/api/trips")
    spans = span_exporter.get_finished_spans()
    slow = [s for s in spans if (s.end_time - s.start_time) > 500_000_000]  # 500ms
    assert len(slow) == 0
```

**This catches in CI:**
- N+1 query bugs
- Slow endpoints
- Unhandled exceptions producing error spans
- Missing expected DB operations

---

## Phase 4 — CD Pipeline + Server Connection

### 4.1 How the Pipeline Reaches Your Server

The pipeline SSHes into your server exactly like you do manually,
using a stored private key saved as a GitHub Secret.

```
GitHub Actions runner
       │  SSH (port 22)
       ▼
Your Server (VPS / EC2 / DigitalOcean)
       ├── docker compose pull
       ├── docker compose up -d
       ├── alembic upgrade head
       └── curl /health
```

**GitHub Secrets to add** (`Repo → Settings → Secrets → Actions`):
```
SERVER_HOST        = your.server.ip.address
SERVER_USER        = ubuntu (or root)
SERVER_SSH_KEY     = your private key (paste contents)
STAGING_HOST       = staging.server.ip
DATABASE_URL       = postgresql://...
SECRET_KEY         = your-secret-key
```

### 4.2 What Gets Automated

| Operation | Before Pipeline | After Pipeline |
|-----------|----------------|----------------|
| `git pull` on server | You SSH + type | Automatic |
| `docker compose up` | You SSH + type | Automatic |
| `alembic upgrade head` | You SSH + type | Automatic |
| DB backup before migration | Often forgotten | Pipeline step |
| Rollback if deploy fails | Panic + manual | Automatic |
| Secrets / .env management | Manual copy | Injected via Secrets |

### 4.3 Safe Migration Order in Pipeline

```
1. Build new Docker image
2. Push to registry
3. BACKUP DATABASE          ← before touching anything
4. Pull new image on server
5. alembic upgrade head     ← migration
6. Restart containers       ← new app on new schema
7. Health check /health
8. FAIL → alembic downgrade -1 + pull previous image tag + restart
```

### 4.4 Image Registry + Tagging

Use GitHub Container Registry (GHCR) — free, tight GitHub integration:

```
ghcr.io/yourrepo/fleet-backend:latest          ← last prod deploy
ghcr.io/yourrepo/fleet-backend:1.4.2           ← semantic version
ghcr.io/yourrepo/fleet-backend:staging-abc1234 ← staging (git sha)
ghcr.io/yourrepo/fleet-backend:dev-abc1234     ← dev/PR builds (ephemeral)
```

### 4.5 One-Time Server Setup (manual, done once)

```bash
# On your server
apt install docker docker-compose-plugin git curl

mkdir -p /opt/fleet-app
cd /opt/fleet-app
git clone https://github.com/yourrepo/rr4 .

# Create .env manually (stays on server, never in git)
nano .env

# Add GitHub Actions deploy user public key to authorized_keys
echo "ssh-rsa AAAA..." >> ~/.ssh/authorized_keys
```

After this — all deploys are fully automated.

---

## Phase 5 — Prometheus + Grafana (Metrics Layer)

### 5.1 What Each Tool Does

| Tool | Role | What it sees |
|------|------|-------------|
| SigNoz | Traces + APM | Request flows, slow spans, error traces |
| Prometheus | Metrics collection | Numbers over time: counts, rates, latencies |
| Grafana | Visualization | Dashboards + alerts on top of Prometheus |
| Loki (optional) | Log aggregation | Searchable structured logs |

### 5.2 Connect Prometheus to FastAPI

```bash
pip install prometheus-fastapi-instrumentator
```

Add to `requirements.txt`:
```
prometheus-fastapi-instrumentator>=6.0.0
```

In `app/main.py` (after `app = FastAPI(...)`):
```python
if settings.PROMETHEUS_ENABLED:
    from prometheus_fastapi_instrumentator import Instrumentator
    Instrumentator().instrument(app).expose(app)
    # exposes /metrics endpoint — Prometheus scrapes this
```

Add to `app/config.py`:
```python
PROMETHEUS_ENABLED: bool = False
```

### 5.3 Configure Prometheus to Scrape Your App

In `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'fleet-backend'
    scrape_interval: 15s
    static_configs:
      - targets: ['localhost:8000']   # scrapes /metrics endpoint
```

Run Prometheus:
```bash
docker run -d \
  -p 9090:9090 \
  -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

Dashboard at `http://localhost:9090`

### 5.4 Install + Connect Grafana

```bash
docker run -d -p 3000:3000 grafana/grafana
# Dashboard at http://localhost:3000 (admin/admin)
```

Add Prometheus data source:
`Grafana → Connections → Data sources → Add → Prometheus → http://localhost:9090`

Import FastAPI dashboard: `Dashboards → Import → ID: 17175`

You immediately get: request rate, latency histogram, error rate per endpoint, active requests.

### 5.5 Metrics You Get for Free (from your stack)

From `prometheus-fastapi-instrumentator`:
- `http_requests_total` — total requests by endpoint + status code
- `http_request_duration_seconds` — latency histogram (p50, p95, p99)
- `http_requests_in_progress` — active concurrent requests

From `opentelemetry-instrumentation-sqlalchemy`:
- DB query duration per query type
- Connection pool usage

---

## Phase 6 — Quality Gates (APM-Driven Deploy Decisions)

### 6.1 The Problem with Standard Pipelines

Standard CI/CD deploys and immediately calls it done.
Nobody checks: did error rate spike? Did latency jump? Are there new exception traces?

### 6.2 Quality Gate Concept

After deploying to staging, **pause and interrogate your monitoring stack**
before allowing the production deploy:

```
Deploy to staging
      ↓
Run smoke tests (functional)
      ↓
Wait 3 minutes (let traffic generate signals)
      ↓
quality_gate.py queries:
  ├── Prometheus: error rate < 1%?
  ├── Prometheus: p99 latency < 500ms?
  ├── Prometheus: DB query time < 200ms?
  ├── SigNoz: any new error traces in last 5m?
  └── SigNoz: any 500 spans?
      ↓ ALL PASS        ↓ ANY FAIL
 promote to prod   block + rollback + notify
```

### 6.3 Specific Checks for Your App

| Check | Source | Threshold |
|-------|--------|-----------|
| Overall HTTP error rate | Prometheus | < 1% |
| `/api/auth/*` p99 latency | Prometheus/SigNoz | < 300ms |
| `/api/trips/*` p99 latency | Prometheus/SigNoz | < 500ms |
| DB query time p99 | SigNoz SQLAlchemy spans | < 200ms |
| Redis errors | Prometheus | 0 |
| New exception traces | SigNoz | 0 new exceptions |

### 6.4 How Pipeline Queries Monitoring (Architecture)

**Important:** GitHub runner cannot reach `localhost` on your machine.
The quality gate script must run ON the server itself (via SSH),
where `localhost` means the server's own SigNoz/Prometheus.

```
GitHub Runner
      │  SSH into staging server
      ▼
Staging Server
      ├── quality_gate.py runs HERE
      │     ├── requests.get("http://localhost:9090/...")  ← Prometheus
      │     └── requests.get("http://localhost:3301/...")  ← SigNoz
      └── pass/fail → pipeline proceeds or rolls back
```

### 6.5 Connecting Local Monitoring to Pipeline (Options)

| Option | How | Reliability | Use Case |
|--------|-----|-------------|----------|
| Tailscale VPN | Runner + laptop join same VPN network | Medium (laptop must be on) | Local dev experimentation |
| OTEL Collector in CI | Spin up collector as Docker service inside CI job | High | Trace-based testing in CI |
| InMemorySpanExporter | Pure Python, no external service | High | Unit/integration test assertions |
| Ngrok tunnel | Expose local port publicly | Low (URL changes) | Quick one-off experiment only |

**Recommended approach:**
- **CI (every PR):** `InMemorySpanExporter` — zero infra, pure pytest, catches N+1 bugs + slow spans + errors
- **CD quality gate:** Run `quality_gate.py` on staging server via SSH — queries localhost there
- **Local development:** Keep SigNoz running locally as-is for developer visibility

### 6.6 Pipeline Evolution Over Time

```
Phase 1 (now):     ci.yml — lint + pytest, no server needed
Phase 2 (VPS):     cd-staging.yml — auto-deploy, smoke tests
Phase 3 (growing): quality_gate.py — Prometheus + SigNoz gate
Phase 4 (scale):   load tests in staging (Locust/k6)
Phase 5 (mature):  canary deploys, auto-rollback on metric breach
```

---

## Phase 7 — Kubernetes (Future, When Scaling)

### 7.1 When to Switch from Docker Compose to K8s

Switch when you need:
- More than 1 server
- Paying users (zero-downtime deploys)
- Auto-scaling based on load
- Self-healing (auto-restart crashed containers)

Keep Docker Compose for local development always.

### 7.2 What K8s Adds Over Docker Compose

| Need | Docker Compose | Kubernetes |
|------|---------------|------------|
| Auto-restart crashed containers | Basic | Yes, with health checks |
| Scale replicas up/down | Manual | Automatic (HPA) |
| Zero-downtime deploys | No | Rolling updates |
| Secret management | .env files | Secrets + Vault |
| Multi-node | No | Yes |
| Traffic routing / HTTPS | No | Ingress controllers |

### 7.3 K8s File Structure (when ready)

```
k8s/
  namespaces/
    staging.yaml
    production.yaml
  backend/
    deployment.yaml    ← replicas, image, env
    service.yaml       ← internal ClusterIP
    ingress.yaml       ← external HTTPS
    hpa.yaml           ← auto-scale on CPU/memory
  postgres/
    statefulset.yaml   ← or use managed DB (RDS / Cloud SQL)
  redis/
    deployment.yaml    ← or use managed Redis
  configmaps/
    backend-config.yaml
  secrets/
    backend-secrets.yaml  ← use Sealed Secrets or Vault
```

---

## Full Stack Picture (Everything Connected)

```
Your FastAPI app
    │
    ├─→ /metrics endpoint ──────────→ Prometheus (scrapes every 15s)
    │                                      │
    │                                      └─→ Grafana (dashboards + alerts)
    │
    ├─→ OTLP traces (port 4317) ────→ SigNoz (traces + spans + APM)
    │
    └─→ Logs (stdout / Loki handler)→ Loki ──→ Grafana (log explorer)

CI/CD Pipeline
    │
    ├─→ GitHub Actions
    │     ├── ci.yml    (every PR: lint, pytest, docker build, trivy scan)
    │     ├── cd-staging.yml  (develop merge: deploy + smoke test + quality gate)
    │     └── cd-prod.yml     (staging merge: deploy to prod)
    │
    ├─→ Docker image → GHCR registry
    └─→ Deploy → Docker Compose (now) → Kubernetes (later)
```

---

## Master Priority Checklist

### Immediate (no server needed)
- [ ] Implement OpenTelemetry in FastAPI (`app/telemetry.py` + config + main.py)
- [ ] Add `OTEL_ENABLED` feature flag to `.env`
- [ ] Create `develop` and `staging` branches
- [ ] Set branch protection rules on GitHub
- [ ] Write `ci.yml` — lint + pytest with real Postgres/Redis services
- [ ] Add `InMemorySpanExporter` tests for trace assertions

### When ready to deploy (need a VPS)
- [ ] Set up VPS (DigitalOcean / AWS / Hetzner)
- [ ] One-time server setup (Docker, git clone, .env)
- [ ] Add GitHub Secrets (SSH key, DB URL, etc.)
- [ ] Write `cd-staging.yml` — auto-deploy on develop merge
- [ ] Add SigNoz + Prometheus to staging server's Docker Compose
- [ ] Write `smoke_test.py`

### Growing stage
- [ ] Add `prometheus-fastapi-instrumentator` to FastAPI
- [ ] Install + connect Grafana, import FastAPI dashboard ID 17175
- [ ] Write `quality_gate.py` — Prometheus + SigNoz checks
- [ ] Wire quality gate into `cd-staging.yml`
- [ ] Write `cd-prod.yml` — production deploy with auto-rollback
- [ ] Add coverage threshold to CI (fail if < 70%)

### Mature stage
- [ ] Loki for log aggregation
- [ ] Load testing in staging pipeline (Locust or k6)
- [ ] Canary deployments
- [ ] Migrate to Kubernetes

---

## Team & Multi-Developer Env File Strategy

### Current Problem (Must Fix)
`.gitignore` has env lines commented out — all env files including `.env.production`
with real secrets are currently tracked by git. This is a security risk and causes
conflicts when other devs pull.

```
# backend/.gitignore currently has:
#.env               ← commented out = BEING COMMITTED (wrong)
#.env.production    ← commented out = BEING COMMITTED (wrong)
```

### Fix 1 — Uncomment .gitignore
```
#.env           →   .env
#.env.local     →   .env.local
#.env.production →  .env.production
```

### Fix 2 — Remove from git tracking (one time)
```bash
git rm --cached backend/.env
git rm --cached backend/.env.production
git commit -m "fix: stop tracking real env files"
```
Files stay on disk — just removed from git history going forward.

---

### What Gets Committed vs What Stays Local

| File | Committed to git | Who uses it |
|------|-----------------|-------------|
| `.env.example` | ✅ YES — safe template | Every dev copies to `.env` on first setup |
| `.env.docker` | ✅ YES — safe docker defaults | Docker Compose dev environment |
| `.env` | ❌ NO — real local secrets | Each dev's own machine only |
| `.env.production` | ❌ NO — real prod secrets | Lives only on GCP server, never in git |

---

### OTEL/Prometheus Flags — Team Rule

**Both `.env.example` and `.env.docker` must have the flags with `false` defaults:**

```env
# .env.example and .env.docker
OTEL_ENABLED=false              ← default off — nobody breaks on pull
OTEL_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=fleet-management-api
PROMETHEUS_ENABLED=false        ← default off
```

**Result for other devs:**
- Dev pulls → gets flags → app works fine (both false, nothing loads)
- Dev wants tracing → they flip `true` in their own `.env` (not committed)
- Nobody's app breaks because they don't have SigNoz running

**For Docker specifically (`host.docker.internal`):**
```env
# .env.docker — app runs inside container, SigNoz runs on host Windows machine
OTEL_ENDPOINT=http://host.docker.internal:4317
```
`localhost` inside a container = the container itself, not the Windows host.
`host.docker.internal` = the actual Windows machine. Works on Windows + Mac Docker.
On Linux servers use the host gateway IP instead.

---

### New Developer Onboarding Steps (after fixes above)

```
1. git clone the repo
2. cd backend
3. cp .env.example .env           ← copy template
4. Edit .env — fill in real values (DB password, SECRET_KEY, etc.)
5. docker compose up -d
6. App runs — OTEL/Prometheus off by default, no errors
7. Optional: start SigNoz → flip OTEL_ENABLED=true in .env → see traces
```

---

### GCP Production Server Rule
`.env.production` lives ONLY on the GCP server — never in git.
Set it up manually once on the server:
```bash
# On GCP server — done once by team lead
nano /opt/fleet-app/.env.production
# Add all real production values including:
OTEL_ENABLED=false        ← keep false until SigNoz deployed on GCP
PROMETHEUS_ENABLED=false  ← keep false until Prometheus deployed on GCP
```
When SigNoz is deployed on GCP → flip to `true` once → leave forever.

---

## Key Concepts Quick Reference

**Runner:** Fresh Ubuntu machine GitHub spins up for each pipeline run. Destroyed after. Nothing persists between runs.

**Quality Gate:** Script that queries Prometheus/SigNoz after staging deploy. Blocks production deploy if metrics fail thresholds.

**Feature Flag (env var):** Controls infra/integration features. Needs restart. Zero overhead when off.

**Feature Flag (DB/Redis):** Controls business features. Instant toggle, no restart, no deploy.

**OTLP:** OpenTelemetry Protocol. How your app sends traces to SigNoz. Port 4317 (gRPC) or 4318 (HTTP).

**InMemorySpanExporter:** OpenTelemetry test utility. Captures spans in memory during pytest. No SigNoz server needed. Use in CI.

**GHCR:** GitHub Container Registry. Where built Docker images are stored between build and deploy. Free with GitHub.

**Alembic:** Your DB migration tool. Always runs migrations BEFORE the new app version starts, AFTER DB backup.
