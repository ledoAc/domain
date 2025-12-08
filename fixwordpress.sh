#!/bin/bash

# ============================================
# WordPress Core Repair Script
# Enhanced version with better error handling
# ============================================

set -euo pipefail  # Strict mode

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to set correct permissions
set_permissions() {
    local path="$1"
    log_info "Setting permissions for: $path"
    
    # Directories: 755
    if find "$path" -type d -exec chmod 755 {} \; 2>/dev/null; then
        log_info "Directory permissions: 755"
    else
        log_warn "Some directory permissions could not be set"
    fi
    
    # Files: 644 (не 664!)
    if find "$path" -type f -exec chmod 644 {} \; 2>/dev/null; then
        log_info "File permissions: 644"
    else
        log_warn "Some file permissions could not be set"
    fi
    
    # Special permissions for wp-config.php
    if [[ -f "$path/wp-config.php" ]]; then
        if chmod 640 "$path/wp-config.php" 2>/dev/null; then
            log_info "wp-config.php permissions: 640"
        else
            log_warn "Could not change wp-config.php permissions"
        fi
    fi
}

# Function to detect web server user
detect_web_user() {
    # ... (залишається без змін)
}

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to check for plugin/theme updates
check_updates() {
    # ... (залишається без змін)
}

# Function to list all users
list_users() {
    # ... (залишається без змін)
}

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [WP_PATH]

Options:
  -h, --help      Show this help message
  -u, --user      Specify web server user (default: auto-detect)
  -g, --group     Specify web server group (default: same as user)
  -s, --skip-permissions  Skip permission fixing
  -v, --verbose   Enable verbose output

WP_PATH           WordPress directory (default: current directory)

Examples:
  $(basename "$0") /var/www/wordpress
  $(basename "$0") --user=vitobpmv /var/www/html
  $(basename "$0") -s  # Skip permission fixing
EOF
    exit 0
}

# Parse arguments
# ... (залишається без змін)

# -------------------------
# 2. Fix permissions (optional) - ВИПРАВЛЕНО
# -------------------------
if [[ "$FIX_PERMISSIONS" == true ]]; then
    log_info "Fixing permissions..."
    
    # Skip ownership change if user is current user or doesn't exist
    if [[ "$WP_USER" == "$(whoami)" ]]; then
        log_info "User is current user, skipping ownership change"
        SKIP_OWNER=true
    elif ! id "$WP_USER" &>/dev/null; then
        log_warn "User '$WP_USER' does not exist. Skipping ownership change."
        SKIP_OWNER=true
    else
        SKIP_OWNER=false
    fi
    
    if [[ "$SKIP_OWNER" == false ]]; then
        log_info "Changing ownership to $WP_USER:$WP_GROUP..."
        if chown -R "$WP_USER:$WP_GROUP" "$WP_PATH" 2>/dev/null; then
            log_info "Ownership changed successfully"
        else
            log_warn "Could not change ownership (permissions denied)"
            log_info "Trying with sudo..."
            if command -v sudo &>/dev/null && sudo chown -R "$WP_USER:$WP_GROUP" "$WP_PATH" 2>/dev/null; then
                log_info "Ownership changed with sudo"
            else
                log_warn "Failed to change ownership. Continuing with current permissions."
            fi
        fi
    fi
    
    # Використовуємо функцію для встановлення прав
    set_permissions "$WP_PATH"
    
    log_info "Initial permissions fixed"
fi

# -------------------------
# 3. Detect WP version
# -------------------------
# ... (залишається без змін)

# -------------------------
# 4. Backup wp-content and wp-config
# -------------------------
# ... (залишається без змін)

# -------------------------
# 5. Download clean core - ВИПРАВЛЕНО
# -------------------------
log_info "Downloading clean core files for version $WP_VERSION..."

CACHE_DIR="$HOME/.wp-core-cache"
mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/wordpress-$WP_VERSION.zip"

if [[ ! -f "$CACHE_FILE" ]] || [[ "$VERBOSE" == true ]]; then
    log_info "Downloading WordPress $WP_VERSION..."
    wp core download \
        --version="$WP_VERSION" \
        --path="/tmp/wordpress-$WP_VERSION" \
        --force \
        --skip-content \
        --allow-root \
        --quiet="$([[ "$VERBOSE" != true ]] && echo "--quiet")"
    
    # ВАЖЛИВО: встановлюємо правильні права перед запаковуванням в кеш
    log_info "Setting correct permissions for downloaded files..."
    find "/tmp/wordpress-$WP_VERSION" -type d -exec chmod 755 {} \; 2>/dev/null
    find "/tmp/wordpress-$WP_VERSION" -type f -exec chmod 644 {} \; 2>/dev/null
    
    cd "/tmp/wordpress-$WP_VERSION" && zip -qr "$CACHE_FILE" . && cd - >/dev/null
    rm -rf "/tmp/wordpress-$WP_VERSION"
fi

log_info "Extracting core files..."
if unzip -q -o "$CACHE_FILE" -d "$WP_PATH" 2>/dev/null; then
    log_info "Core files extracted"
    
    # ВАЖЛИВО: встановлюємо права після розпаковки
    if [[ "$FIX_PERMISSIONS" == true ]]; then
        log_info "Setting permissions for extracted core files..."
        set_permissions "$WP_PATH"
    fi
else
    log_error "Failed to extract core files"
    exit 1
fi

# Restore wp-content and wp-config
log_info "Restoring wp-content and configuration..."
[[ -d "$BACKUP_DIR/wp-content" ]] && cp -a "$BACKUP_DIR/wp-content/." "wp-content/" 2>/dev/null || log_warn "Could not restore wp-content"
[[ -f "$BACKUP_DIR/wp-config.php" ]] && cp -f "$BACKUP_DIR/wp-config.php" . 2>/dev/null || log_warn "Could not restore wp-config.php"

# ВАЖЛИВО: встановлюємо права для відновлених файлів
if [[ "$FIX_PERMISSIONS" == true ]]; then
    log_info "Setting permissions for restored files..."
    # Права для wp-config.php
    [[ -f "wp-config.php" ]] && chmod 640 wp-config.php 2>/dev/null
    
    # Права для вмісту wp-content
    [[ -d "wp-content" ]] && set_permissions "wp-content"
fi

log_info "Core files updated to clean version"

# -------------------------
# 6. Verify and clean up
# -------------------------
# ... (залишається без змін)

# -------------------------
# 7. Run additional checks
# -------------------------
check_updates
list_users

# -------------------------
# 8. Final permissions check - НОВИЙ РОЗДІЛ
# -------------------------
if [[ "$FIX_PERMISSIONS" == true ]]; then
    log_info "Final permissions verification..."
    
    # Перевіряємо, чи немає файлів з правами 664
    WRONG_PERM_FILES=$(find "$WP_PATH" -type f -perm 664 2>/dev/null | head -10 || true)
    
    if [[ -n "$WRONG_PERM_FILES" ]]; then
        log_warn "Found files with 664 permissions (should be 644):"
        echo "$WRONG_PERM_FILES" | while read -r file; do
            log_warn "  $file"
            # Виправляємо
            chmod 644 "$file" 2>/dev/null || true
        done
        log_info "Fixed file permissions to 644"
    else
        log_info "All files have correct permissions (644)"
    fi
fi

# -------------------------
# 9. Final cleanup
# -------------------------
log_info "Cleaning up temporary files..."
rm -rf "$BACKUP_DIR" 2>/dev/null || true

log_info "========================================"
log_info "WordPress repair completed successfully!"
log_info "========================================"

# Security plugin recommendation
SECURITY_PLUGINS=(
    "Wordfence Security"
    "Sucuri Security"
    "iThemes Security"
    "All In One WP Security & Firewall"
    "MalCare Security"
)

RANDOM_PLUGIN=${SECURITY_PLUGINS[$RANDOM % ${#SECURITY_PLUGINS[@]}]}

cat << EOF

Summary:
- WordPress path: $WP_PATH
- Version: $WP_VERSION
- Permissions fixed: $FIX_PERMISSIONS
- Web user: $WP_USER:$WP_GROUP

Recommended next steps:
1. Clear browser cache
2. Update plugins and themes listed above
3. Review user list and remove unused accounts
4. Install security plugin like: ${YELLOW}$RANDOM_PLUGIN${NC}
5. Change all administrative passwords
6. Enable regular backups
7. Check .htaccess for suspicious code

EOF

exit 0
