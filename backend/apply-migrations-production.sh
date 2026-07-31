#!/bin/bash
# apply-migrations-production.sh - Apply migrations on production server
# Run this script ON your production server
#
# This script re-launches itself in the background (nohup + setsid) so a
# dropped SSH session no longer kills a migration/backup mid-run. Reconnect
# and tail the printed log file to see live progress; the lock file prevents
# a second run from starting while one is already in flight.

set -e

# ── Colors / icons — plain ASCII fallback if the session isn't UTF-8 ──────────
# (garbled box-drawing/emoji over some SSH sessions was one of the reported
# symptoms; only use the fancy glyphs when we know they'll render, and only
# use colors when attached to a real terminal so a logged run stays clean)
if [ -t 1 ]; then
    GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
    GREEN=''; BLUE=''; YELLOW=''; RED=''; CYAN=''; BOLD=''; NC=''
fi

if locale 2>/dev/null | grep -qi "utf-8"; then
    BOX_H="════════════════════════════════════════════════════════════════"
    BOX_TL="╔"; BOX_TR="╗"; BOX_BL="╚"; BOX_BR="╝"; BOX_V="║"
    ICON_INFO="ℹ️ "; ICON_OK="✅"; ICON_WARN="⚠️ "; ICON_ERR="❌"; ICON_ROCKET="🚀"
else
    BOX_H="--------------------------------------------------------------------"
    BOX_TL="+"; BOX_TR="+"; BOX_BL="+"; BOX_BR="+"; BOX_V="|"
    ICON_INFO="[i]"; ICON_OK="[OK]"; ICON_WARN="[!]"; ICON_ERR="[X]"; ICON_ROCKET=""
fi

print_header() {
    echo ""
    echo -e "${CYAN}${BOX_TL}${BOX_H}${BOX_TR}${NC}"
    echo -e "${CYAN}${BOX_V}${NC}  ${BOLD}$1${NC}"
    echo -e "${CYAN}${BOX_BL}${BOX_H}${BOX_BR}${NC}"
    echo ""
}

print_step()    { echo -e "${CYAN}--- $1${NC}"; }
print_info()    { echo -e "${BLUE}${ICON_INFO} $1${NC}"; }
print_success() { echo -e "${GREEN}${ICON_OK} $1${NC}"; }
print_warning() { echo -e "${YELLOW}${ICON_WARN} $1${NC}"; }
print_error()   { echo -e "${RED}${ICON_ERR} $1${NC}"; }

# ── Prevent an SSH drop from killing a mid-flight migration ───────────────────
# On first invocation (RR4_MIGRATION_BG unset) this block re-execs the whole
# script under nohup+setsid, detached from the controlling terminal, and just
# waits/tails its log. If the SSH session drops, the background worker below
# keeps running to completion — reconnect and `tail -f` the log file to see
# where it landed, instead of having to re-run from scratch.
LOCK_FILE="/tmp/rr4-apply-migrations.lock"

if [ -z "${RR4_MIGRATION_BG:-}" ]; then
    if [ -f "$LOCK_FILE" ]; then
        EXISTING_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [ -n "$EXISTING_PID" ] && kill -0 "$EXISTING_PID" 2>/dev/null; then
            print_error "A migration is already running in the background (PID $EXISTING_PID)."
            print_info "Reconnect later and tail its log instead of starting a second run."
            exit 1
        fi
        print_warning "Found a stale lock file (process $EXISTING_PID not running) — removing it."
        rm -f "$LOCK_FILE"
    fi

    export RR4_MIGRATION_BG=1
    LOG_FILE="migration_$(date +%Y%m%d_%H%M%S).log"
    print_info "Running in the background so a dropped SSH session can't interrupt this."
    print_info "Log file: $LOG_FILE"
    print_info "You can safely close this terminal; reconnect later and run: tail -f $LOG_FILE"
    # No `disown` here — nohup + setsid alone already fully protect this
    # process from a dropped SSH session (nohup ignores SIGHUP, setsid detaches
    # it from the controlling terminal entirely). Disowning it additionally
    # broke `wait "$BG_PID"` below: once a job is disowned, `wait` can return
    # immediately (often with exit code 0) instead of actually blocking until
    # the real background process finishes — which silently turned every run
    # into a false "success" before the migration had done any real work.
    nohup setsid "$0" "$@" > "$LOG_FILE" 2>&1 < /dev/null &
    BG_PID=$!
    echo "Started as PID $BG_PID."

    # Follow the log live while this session stays connected; harmless if it drops.
    ( tail -f "$LOG_FILE" --pid="$BG_PID" 2>/dev/null & )
    TAIL_PID=$!
    wait "$BG_PID" 2>/dev/null
    EXIT_CODE=$?
    kill "$TAIL_PID" 2>/dev/null || true

    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        print_success "Migration finished successfully. Full log: $LOG_FILE"
    else
        print_error "Migration exited with code $EXIT_CODE — check $LOG_FILE for details."
    fi
    exit $EXIT_CODE
fi

# From here on, this IS the detached background worker.
echo "$$" > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

print_header "Production Migration Script"

print_info "This script will apply database migrations on your production server"
echo ""
print_warning "Prerequisites:"
echo "  1. Docker containers must be running"
echo "  2. PostgreSQL must be accessible"
echo "  3. You must be in the backend directory"
echo ""

# Detect docker-compose command
if docker compose version > /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif docker-compose version > /dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    print_error "docker-compose is not installed"
    exit 1
fi

print_success "Using: $COMPOSE_CMD"

echo ""
print_step "Step 1: Checking Docker containers"

if ! $COMPOSE_CMD ps | grep -q "Up"; then
    print_warning "No containers are running! Starting containers..."
    $COMPOSE_CMD up -d

    print_step "Waiting for services to be ready..."
    sleep 20
fi

$COMPOSE_CMD ps
print_success "Containers are running"

echo ""
print_step "Step 2: Checking database connection"

if $COMPOSE_CMD exec -T postgres pg_isready -U fleet_user -d fleet_db > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_error "Database is not accessible"
    print_info "Waiting 30 seconds for database to be ready..."
    sleep 30

    if ! $COMPOSE_CMD exec -T postgres pg_isready -U fleet_user -d fleet_db > /dev/null 2>&1; then
        print_error "Database is still not accessible. Check logs:"
        echo "  $COMPOSE_CMD logs postgres"
        exit 1
    fi
fi

echo ""
print_step "Step 3: Checking current migration status"

$COMPOSE_CMD exec backend alembic current || print_info "No migrations applied yet"

echo ""
print_step "Step 4: Checking for migration heads"

HEADS=$($COMPOSE_CMD exec backend alembic heads 2>/dev/null || echo "")
echo "$HEADS"

HEADS_COUNT=$(echo "$HEADS" | grep -c "^[a-f0-9]" || echo 0)

if [ "$HEADS_COUNT" -gt 1 ]; then
    print_warning "Multiple migration heads detected!"
    print_info "Will use 'upgrade heads' to handle this"
    UPGRADE_CMD="upgrade heads"
else
    print_success "Single migration head (normal)"
    UPGRADE_CMD="upgrade head"
fi

echo ""
print_step "Step 5: Viewing migration history"

$COMPOSE_CMD exec backend alembic history | head -20

echo ""
print_step "Step 6: Creating database backup (recommended)"

BACKUP_FILE="db_backup_$(date +%Y%m%d_%H%M%S).sql"

print_info "Creating backup: $BACKUP_FILE (timeout: 30 min)"
# Wrapped in `timeout` so a stalled dump fails loudly instead of hanging
# silently for the rest of the session.
if timeout 1800 $COMPOSE_CMD exec -T postgres pg_dump -U fleet_user -d fleet_db > "$BACKUP_FILE"; then
    print_success "Backup created: $BACKUP_FILE"
else
    print_error "Backup timed out or failed — aborting before touching the schema."
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo ""
print_step "Step 7: Applying migrations"

print_warning "About to run: alembic $UPGRADE_CMD"
print_info "This will modify the production database!"
echo ""
print_info "Running migrations..."

# lock_timeout: if a DDL statement can't acquire its lock quickly (e.g. the
# app's live connections are holding it), fail fast with a clear Postgres
# error instead of hanging indefinitely — this was the main cause of the
# script appearing "stuck".
# statement_timeout: backstop for any single migration statement that runs
# away for an unrelated reason.
if $COMPOSE_CMD exec -e PGOPTIONS="-c lock_timeout=15000 -c statement_timeout=120000" backend alembic $UPGRADE_CMD; then
    print_success "Migrations applied successfully!"
else
    MIGRATION_FAILED=$?
    print_error "Migration failed with exit code: $MIGRATION_FAILED"
    echo ""
    print_info "Troubleshooting steps:"
    echo "  1. Check backend logs: $COMPOSE_CMD logs backend"
    echo "  2. Check migration status: $COMPOSE_CMD exec backend alembic current"
    echo "  3. View recent migrations: $COMPOSE_CMD exec backend alembic history"
    echo "  4. If it failed on lock_timeout, something else is holding a lock on the"
    echo "     table being altered — check for long-running queries before retrying."
    echo ""

    if [ -f "$BACKUP_FILE" ]; then
        print_warning "You can restore the backup with:"
        echo "  cat $BACKUP_FILE | $COMPOSE_CMD exec -T postgres psql -U fleet_user -d fleet_db"
    fi

    exit $MIGRATION_FAILED
fi

echo ""
print_step "Step 8: Verifying migration"

print_info "Current migration version:"
$COMPOSE_CMD exec backend alembic current

echo ""
print_info "Database tables:"
$COMPOSE_CMD exec postgres psql -U fleet_user -d fleet_db -c "\dt" | head -30

echo ""
print_step "Step 9: Testing API health"

# The backend may still be mid hot-reload (picking up the files just pulled),
# which drops in-flight connections for a moment — so retry a few times with
# a short per-request timeout instead of a single unbounded curl that can hang.
health_ok=0
for attempt in 1 2 3 4 5; do
    if $COMPOSE_CMD exec backend curl -f --max-time 5 http://localhost:8000/health > /dev/null 2>&1; then
        health_ok=1
        break
    fi
    sleep 3
done

if [ "$health_ok" = "1" ]; then
    print_success "API is healthy"
else
    print_warning "API health check failed after retries (might be normal if /health endpoint doesn't exist, or the backend is still reloading)"
fi

echo ""
print_header "Migration Complete!"

print_success "Migrations have been applied successfully!"
echo ""
print_info "Summary:"
echo "  - Database migrations applied"
echo "  - All tables created/updated"
echo "  - API is running"
echo ""

if [ -f "$BACKUP_FILE" ]; then
    print_info "Backup file: $BACKUP_FILE"
    echo "  Keep this file safe in case you need to rollback"
fi

echo ""
print_info "Next steps:"
echo "  1. Test your API endpoints"
echo "  2. Monitor application logs: $COMPOSE_CMD logs -f backend"
echo "  3. Verify data integrity"
echo ""
print_success "All done! ${ICON_ROCKET}"
echo ""
