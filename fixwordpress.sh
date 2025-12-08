#!/bin/bash

# ============================================
# WordPress Core Repair Script
# Enhanced version with better error handling
# ============================================

set -euo pipefail  # Strict mode

# Colors for output (простіші коди)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Function to check for plugin/theme updates
check_updates() {
    log_info "Checking for available updates..."
    
    echo -e "\n${BLUE}=== PLUGIN UPDATES ===${NC}"
    PLUGIN_UPDATES=$(wp plugin list --fields=name,status,update,version,update_version --allow-root --format=csv 2>/dev/null | grep "available" || true)
    
    if [[ -n "$PLUGIN_UPDATES" ]]; then
        echo "$PLUGIN_UPDATES" | while IFS= read -r line; do
            # Розбираємо CSV рядок
            PLUGIN_NAME=$(echo "$line" | cut -d',' -f1)
            CURRENT_VER=$(echo "$line" | cut -d',' -f4)
            NEW_VER=$(echo "$line" | cut -d',' -f5)
            echo -e "${YELLOW}• $PLUGIN_NAME${NC}: $CURRENT_VER → $NEW_VER"
        done
        PLUGIN_COUNT=$(echo "$PLUGIN_UPDATES" | wc -l)
        echo -e "\n${YELLOW}Found $PLUGIN_COUNT plugin(s) needing update${NC}"
    else
        echo -e "${GREEN}All plugins are up to date${NC}"
    fi
    
    echo -e "\n${BLUE}=== THEME UPDATES ===${NC}"
    THEME_UPDATES=$(wp theme list --fields=name,status,update,version,update_version --allow-root --format=csv 2>/dev/null | grep "available" || true)
    
    if [[ -n "$THEME_UPDATES" ]]; then
        echo "$THEME_UPDATES" | while IFS= read -r line; do
            THEME_NAME=$(echo "$line" | cut -d',' -f1)
            CURRENT_VER=$(echo "$line" | cut -d',' -f4)
            NEW_VER=$(echo "$line" | cut -d',' -f5)
            echo -e "${YELLOW}• $THEME_NAME${NC}: $CURRENT_VER → $NEW_VER"
        done
        THEME_COUNT=$(echo "$THEME_UPDATES" | wc -l)
        echo -e "\n${YELLOW}Found $THEME_COUNT theme(s) needing update${NC}"
    else
        echo -e "${GREEN}All themes are up to date${NC}"
    fi
}

# Function to list all users
list_users() {
    log_info "Listing all WordPress users..."
    
    echo -e "\n${BLUE}=== WORDPRESS USERS ===${NC}"
    
    # Використовуємо текстовий формат для кращої читабельності
    USERS_OUTPUT=$(wp user list --fields=ID,user_login,display_name,user_email,roles --allow-root 2>/dev/null || true)
    
    if [[ -n "$USERS_OUTPUT" ]]; then
        echo "ID | Username | Display Name | Email | Role"
        echo "---|----------|--------------|-------|------"
        echo "$USERS_OUTPUT" | tail -n +2 | while IFS= read -r line; do
            echo "$line"
        done
        
        # Count admin users
        ADMIN_COUNT=$(wp user list --role=administrator --format=count --allow-root 2>/dev/null || echo "0")
        echo -e "\n${YELLOW}Administrators: $ADMIN_COUNT user(s)${NC}"
    else
        log_warn "Could not retrieve user list"
    fi
}

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [WP_PATH]

Options:
  -h, --help      Show this help message
  -u, --user      Specify web server user (default: www-data)
  -g, --group     Specify web server group (default: www-data)
  -s, --skip-permissions  Skip permission fixing
  -v, --verbose   Enable verbose output

WP_PATH           WordPress directory (default: current directory)

Examples:
  $(basename "$0") /var/www/wordpress
  $(basename "$0") --user=nginx --group=nginx /var/www/html
  $(basename "$0") -s  # Skip permission fixing
EOF
    exit 0
}

# Default variables
WP_USER="www-data"
WP_GROUP="www-data"
FIX_PERMISSIONS=true
VERBOSE=false
WP_PATH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -u=*|--user=*)
            WP_USER="${1#*=}"
            shift
            ;;
        -g=*|--group=*)
            WP_GROUP="${1#*=}"
            shift
            ;;
        -s|--skip-permissions)
            FIX_PERMISSIONS=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            ;;
        *)
            WP_PATH="$1"
            shift
            ;;
    esac
done

# Set default path if not provided
WP_PATH="${WP_PATH:-$(pwd)}"
WP_PATH="${WP_PATH%/}"  # Remove trailing slash

log_info "Starting WordPress repair process..."
log_info "WordPress path: $WP_PATH"

# -------------------------
# 1. Validate environment
# -------------------------
if [[ ! -d "$WP_PATH" ]]; then
    log_error "Directory does not exist: $WP_PATH"
    exit 1
fi

if ! command -v wp &> /dev/null; then
    log_error "WP-CLI is not installed or not in PATH"
    log_info "Install with: curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
    exit 1
fi

cd "$WP_PATH" || {
    log_error "Cannot enter directory: $WP_PATH"
    exit 1
}

# Check if this is a WordPress directory
if [[ ! -f "wp-config.php" ]]; then
    log_warn "wp-config.php not found. Is this a WordPress directory?"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# -------------------------
# 2. Fix permissions (optional)
# -------------------------
if [[ "$FIX_PERMISSIONS" == true ]]; then
    log_info "Fixing permissions..."
    
    # Check if user/group exists (правильна перевірка)
    if ! id -u "$WP_USER" &>/dev/null; then
        log_warn "User '$WP_USER' does not exist. Skipping ownership change."
        SKIP_OWNER=true
    elif ! getent group "$WP_GROUP" &>/dev/null; then
        log_warn "Group '$WP_GROUP' does not exist. Skipping ownership change."
        SKIP_OWNER=true
    else
        SKIP_OWNER=false
    fi
    
    if [[ "$SKIP_OWNER" == false ]]; then
        # Change ownership
        if command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
            sudo chown -R "$WP_USER:$WP_GROUP" "$WP_PATH"
            log_info "Changed ownership to $WP_USER:$WP_GROUP"
        else
            log_warn "sudo access required for ownership change"
            log_info "Trying to change ownership without sudo..."
            chown -R "$WP_USER:$WP_GROUP" "$WP_PATH" 2>/dev/null || \
                log_warn "Could not change ownership (permissions denied)"
        fi
    fi
    
    # Set directory permissions (без sudo)
    if find "$WP_PATH" -type d -exec chmod 755 {} \; 2>/dev/null; then
        log_debug "Directory permissions set to 755"
    else
        log_warn "Some directory permissions could not be set"
    fi
    
    # Set file permissions (без sudo)
    if find "$WP_PATH" -type f -exec chmod 644 {} \; 2>/dev/null; then
        log_debug "File permissions set to 644"
    else
        log_warn "Some file permissions could not be set"
    fi
    
    # Special permissions for wp-config.php
    if [[ -f "wp-config.php" ]]; then
        if chmod 640 wp-config.php 2>/dev/null; then
            log_info "Set secure permissions for wp-config.php (640)"
        else
            log_warn "Could not change wp-config.php permissions"
        fi
    fi
    
    log_info "Permissions fixed"
fi

# -------------------------
# 3. Detect WP version
# -------------------------
log_info "Detecting WordPress version..."
WP_VERSION=$(wp core version --allow-root 2>/dev/null || true)

if [[ -z "$WP_VERSION" ]]; then
    log_error "Cannot detect WP version via WP-CLI"
    log_info "Trying alternative method..."
    
    # Try reading version from version.php
    if [[ -f "wp-includes/version.php" ]]; then
        WP_VERSION=$(grep "^\$wp_version" wp-includes/version.php | cut -d"'" -f2)
    fi
    
    if [[ -z "$WP_VERSION" ]]; then
        log_error "Could not detect WordPress version"
        exit 1
    fi
fi

log_info "Detected WP version: $WP_VERSION"

# -------------------------
# 4. Backup wp-content and wp-config
# -------------------------
BACKUP_DIR="/tmp/wp-backup-$(date +%Y%m%d-%H%M%S)"
log_info "Creating backup in: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"
cp -a wp-config.php "$BACKUP_DIR/" 2>/dev/null || log_warn "Could not backup wp-config.php"
[[ -d "wp-content" ]] && cp -a wp-content "$BACKUP_DIR/" 2>/dev/null || log_warn "Could not backup wp-content"

log_info "Backup created at: $BACKUP_DIR"

# -------------------------
# 5. Download clean core
# -------------------------
log_info "Downloading clean core files for version $WP_VERSION..."

# Check for existing download
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
    
    # Cache the download
    cd "/tmp/wordpress-$WP_VERSION" && zip -qr "$CACHE_FILE" . && cd - >/dev/null
    rm -rf "/tmp/wordpress-$WP_VERSION"
    log_debug "WordPress downloaded and cached"
fi

# Extract from cache
log_info "Extracting core files..."
if unzip -q -o "$CACHE_FILE" -d "$WP_PATH" 2>/dev/null; then
    log_debug "Core files extracted successfully"
else
    log_error "Failed to extract core files"
    exit 1
fi

# Restore wp-content and wp-config
log_info "Restoring wp-content and configuration..."
[[ -d "$BACKUP_DIR/wp-content" ]] && cp -a "$BACKUP_DIR/wp-content/." "wp-content/" 2>/dev/null || log_warn "Could not restore wp-content"
[[ -f "$BACKUP_DIR/wp-config.php" ]] && cp -f "$BACKUP_DIR/wp-config.php" . 2>/dev/null || log_warn "Could not restore wp-config.php"

log_info "Core files updated to clean version"

# -------------------------
# 6. Verify and clean up
# -------------------------
log_info "Verifying WordPress core integrity..."

if wp core verify-checksums --allow-root 2>/dev/null; then
    log_info "✓ WordPress core verified successfully"
else
    log_warn "WordPress verification reported issues"
    log_info "Running additional cleanup..."
    
    # Remove suspicious files in wp-admin and wp-includes
    for dir in wp-admin wp-includes; do
        if [[ -d "$dir" ]]; then
            # Find files that shouldn't be there (PHP files uploaded by hackers)
            SUSPICIOUS_FILES=$(find "$dir" -name "*.php" -type f ! -path "*/includes/*" ! -path "*/admin/*" \
                -exec grep -l "eval\|base64_decode\|gzinflate" {} \; 2>/dev/null || true)
            
            if [[ -n "$SUSPICIOUS_FILES" ]]; then
                echo "$SUSPICIOUS_FILES" | while read -r suspicious; do
                    log_warn "Found suspicious file: $suspicious"
                    [[ "$VERBOSE" == true ]] && rm -v "$suspicious" || rm "$suspicious"
                done
            fi
        fi
    done
fi

# -------------------------
# 7. Run additional checks
# -------------------------

# Check for plugin/theme updates
check_updates

# List all users
list_users

# -------------------------
# 8. Final cleanup
# -------------------------
log_info "Cleaning up temporary files..."
if [[ -d "$BACKUP_DIR" ]]; then
    rm -rf "$BACKUP_DIR"
    log_debug "Backup directory removed"
fi

log_info "========================================"
log_info "WordPress repair completed successfully!"
log_info "========================================"

# Summary with specific plugin recommendation
SECURITY_PLUGINS=(
    "Wordfence Security"
    "Sucuri Security"
    "iThemes Security"
    "All In One WP Security & Firewall"
    "MalCare Security"
)

# Вибираємо випадковий плагін
RANDOM_PLUGIN=${SECURITY_PLUGINS[$RANDOM % ${#SECURITY_PLUGINS[@]}]}

cat << EOF

Summary:
- WordPress path: $WP_PATH
- Version: $WP_VERSION
- Permissions fixed: $FIX_PERMISSIONS

Recommended next steps:
1. Clear browser cache
2. Update plugins and themes listed above
3. Review user list and remove unused accounts
4. Install security plugin like: ${YELLOW}$RANDOM_PLUGIN${NC}
5. Change all administrative passwords
6. Enable regular backups

EOF

exit 0
