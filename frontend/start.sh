#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
#  Fleet Management – Frontend Start Script
# ─────────────────────────────────────────────
#
#  Usage:
#    ./start.sh            → production  (docker compose)
#    ./start.sh dev        → development (flutter run -d chrome)
#    ./start.sh build      → build web only (no serve)
#    ./start.sh stop       → stop docker containers

MODE=${1:-prod}

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
    echo "[stop] Stopping containers..."
    docker compose down
    ;;

  # ── Production: Docker + nginx ──────────────
  prod|*)
    echo "[prod] Building & starting with Docker..."
    docker compose up --build
    ;;

esac
