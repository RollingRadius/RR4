#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
#  Fleet Management – Frontend Start Script
# ─────────────────────────────────────────────
#
#  Usage:
#    ./start.sh            → production  (docker)
#    ./start.sh dev        → development (flutter run -d chrome)
#    ./start.sh build      → build web only (no serve)
#    ./start.sh stop       → stop docker container

MODE=${1:-prod}

# Detect docker compose v2 (plugin) vs v1 (standalone binary)
if docker compose version &>/dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose &>/dev/null; then
  DC="docker-compose"
else
  echo "[error] Neither 'docker compose' nor 'docker-compose' found." >&2
  exit 1
fi

echo "[info] Using: $DC"

case "$MODE" in

  # ── Development: hot-reload in Chrome ──────
  dev)
    echo "[dev] Starting Flutter on Chrome..."
    flutter pub get
    flutter run -d chrome \
      --dart-define=API_BASE_URL=http://34.127.125.215:8000
    ;;

  # ── Build only ──────────────────────────────
  build)
    echo "[build] Building Flutter web..."
    flutter pub get
    flutter build web --release \
      --dart-define=API_BASE_URL=http://34.127.125.215:8000
    echo "[build] Done. Output is in build/web/"
    ;;

  # ── Stop containers ─────────────────────────
  stop)
    echo "[stop] Stopping container..."
    $DC down
    ;;

  # ── Production: build locally → ship only static files to Docker ──
  prod|*)
    echo "[prod] Step 1/2 — Building Flutter web locally..."
    flutter pub get
    flutter build web --release \
      --dart-define=API_BASE_URL=http://34.127.125.215:8000

    echo "[prod] Step 2/2 — Building nginx image & starting..."
    $DC up --build
    ;;

esac
