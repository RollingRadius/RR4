#!/bin/bash
# fix-migration-chain.sh - Fix broken migration chain
# This script fixes the down_revision references in migration files

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Fixing Migration Chain                                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

cd alembic/versions

print_info "Backing up migration files..."
BACKUP_DIR="../migration_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp *.py "$BACKUP_DIR/" 2>/dev/null || true
print_success "Backup created: $BACKUP_DIR"

echo ""
print_info "Fixing migration chain..."

# Fix 004_add_capability_system.py
if [ -f "004_add_capability_system.py" ]; then
    print_info "Fixing 004_add_capability_system.py"
    sed -i.bak "s/^revision = /from typing import Sequence, Union\n\nrevision: str = /" 004_add_capability_system.py
    sed -i "s/^down_revision = /down_revision: Union[str, None] = /" 004_add_capability_system.py
    sed -i "s/^branch_labels = /branch_labels: Union[str, Sequence[str], None] = /" 004_add_capability_system.py
    sed -i "s/^depends_on = /depends_on: Union[str, Sequence[str], None] = /" 004_add_capability_system.py
fi

# Fix 008_add_requested_role_field.py
if [ -f "008_add_requested_role_field.py" ]; then
    print_info "Fixing 008_add_requested_role_field.py"
    sed -i.bak "1,/^# revision/s/^# revision/from typing import Sequence, Union\n\n# revision/" 008_add_requested_role_field.py
    sed -i "s/^revision = /revision: str = /" 008_add_requested_role_field.py
    sed -i "s/^down_revision = /down_revision: Union[str, None] = /" 008_add_requested_role_field.py
    sed -i "s/^branch_labels = /branch_labels: Union[str, Sequence[str], None] = /" 008_add_requested_role_field.py
    sed -i "s/^depends_on = /depends_on: Union[str, Sequence[str], None] = /" 008_add_requested_role_field.py
fi

# Fix 009_create_vendors_and_expenses.py - Fix down_revision
if [ -f "009_create_vendors_and_expenses.py" ]; then
    print_info "Fixing 009_create_vendors_and_expenses.py"
    sed -i.bak "s/down_revision.*=.*'add_user_id_to_drivers'/down_revision: Union[str, None] = '008_add_requested_role_field'/" 009_create_vendors_and_expenses.py
fi

# Fix add_user_id_to_drivers.py
if [ -f "add_user_id_to_drivers.py" ]; then
    print_info "Fixing add_user_id_to_drivers.py"
    sed -i.bak "1,/^# revision/s/^# revision/from typing import Sequence, Union\n\n# revision/" add_user_id_to_drivers.py
    sed -i "s/^revision = /revision: str = /" add_user_id_to_drivers.py
    sed -i "s/^down_revision = /down_revision: Union[str, None] = /" add_user_id_to_drivers.py
    sed -i "s/^branch_labels = /branch_labels: Union[str, Sequence[str], None] = /" add_user_id_to_drivers.py
    sed -i "s/^depends_on = /depends_on: Union[str, Sequence[str], None] = /" add_user_id_to_drivers.py
fi

# Remove backup files
rm -f *.bak

echo ""
print_success "Migration chain fixed!"
echo ""
print_info "Migration chain now:"
echo "  001 → 002 → 003 → 004 → 005 → 006 → 007 → 008 →"
echo "  009 → 010 → 011 → 012 → add_user_id_to_drivers"
echo ""
print_info "Next step: Apply migrations"
echo "  docker-compose exec backend alembic upgrade head"
echo ""
