#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
#  Fleet Management – Frontend Start Script
# ─────────────────────────────────────────────
#
#  LOCAL  machine (Flutter installed):
#    ./start.sh build    → flutter build web  (creates build/web/)
#    ./start.sh deploy   → build + upload build/web to server via scp
#
#  SERVER (Docker only, no Flutter):
#    ./start.sh serve    → docker-compose up  (uses existing build/web/)
#    ./start.sh stop     → docker-compose down
#
#  Dev (local, hot-reload):
#    ./start.sh dev      → flutter run -d chrome

# ── Config ─────────────────────────────────────────────────────────────────────
API_BASE_URL="http://34.127.125.215:8000"
SERVER_USER="root"
SERVER_HOST="34.127.125.215"
SERVER_PATH="/home/RR4/frontend"
# ───────────────────────────────────────────────────────────────────────────────

MODE=${1:-help}

# Detect docker compose v2 (plugin) vs v1 (standalone binary)
get_dc() {
  if docker compose version &>/dev/null 2>&1; then
    echo "docker compose"
  elif command -v docker-compose &>/dev/null; then
    echo "docker-compose"
  else
    echo ""
  fi
}

case "$MODE" in

  # ── Dev: hot-reload in Chrome (local) ──────────────────────────────────────
  dev)
    echo "[dev] Starting Flutter on Chrome..."
    flutter pub get
    flutter run -d chrome --dart-define=API_BASE_URL=${API_BASE_URL}
    ;;

  # ── Build: flutter build web (local) ───────────────────────────────────────
  build)
    echo "[build] Building Flutter web..."
    flutter pub get
    flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}
    echo "[build] Done → build/web/"
    ;;

  # ── Deploy: build locally then upload to server ────────────────────────────
  deploy)
    echo "[deploy] Building Flutter web..."
    flutter pub get
    flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

    echo "[deploy] Uploading build/web to ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/"
    scp -r build/web "${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/build/"

    echo "[deploy] Done. SSH in and run:  bash start.sh serve"
    ;;

  # ── Serve: build inside Docker then run nginx ──────────────────────────────
  serve)
    DC=$(get_dc)
    if [ -z "$DC" ]; then
      echo "[error] Docker not found." >&2; exit 1
    fi
    echo "[serve] Building image & starting nginx... (using $DC)"
    $DC up --build -d
    echo "[serve] Running at http://${SERVER_HOST}"
    ;;

  # ── Stop ───────────────────────────────────────────────────────────────────
  stop)
    DC=$(get_dc)
    if [ -z "$DC" ]; then
      echo "[error] Docker not found." >&2; exit 1
    fi
    echo "[stop] Stopping container..."
    $DC down
    ;;

  # ── Help ───────────────────────────────────────────────────────────────────
  help|*)
    echo ""
    echo "Usage: ./start.sh <mode>"
    echo ""
    echo "  LOCAL machine (Flutter installed):"
    echo "    build    → flutter build web"
    echo "    deploy   → build + scp build/web to server"
    echo "    dev      → flutter run -d chrome (hot reload)"
    echo ""
    echo "  SERVER (Docker only):"
    echo "    serve    → docker-compose up -d (nginx)"
    echo "    stop     → docker-compose down"
    echo ""
    ;;

esac
