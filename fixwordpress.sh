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
    echo -e "${GREEN}[INFO]${NC} Setting permissions for: $path"
    
    # Directories: 755
    if find "$path" -type d -exec chmod 755 {} \; 2>/dev/null; then
        echo -e "${GREEN}[INFO]${NC} Directory permissions: 755"
    else
        echo -e "${YELLOW}[WARN]${NC} Some directory permissions could not be set"
    fi
    
    # Files: 644 (не 664!)
    if find "$path" -type f -exec chmod 644 {} \; 2>/dev/null; then
        echo -e "${GREEN}[INFO]${NC} File permissions: 644"
    else
        echo -e "${YELLOW}[WARN]${NC} Some file permissions could not be set"
    fi
    
    # Special permissions for wp-config.php
    if [[ -f "$path/wp-config.php" ]]; then
        if chmod 640 "$path/wp-config.php" 2>/dev/null; then
            echo -e "${GREEN}[INFO]${NC} wp-config.php permissions: 640"
        else
            echo -e "${YELLOW}[WARN]${NC} Could not change wp-config.php permissions"
        fi
    fi
}

# Function to detect web server user (спрощена версія)
detect_web_user() {
    local detected_user=""
    
    # Try common web server users
    for user in www-data nginx apache httpd; do
        if id "$user" &>/dev/null; then
            detected_user="$user"
            break
        fi
    done
    
    # If no web server user found, use current user
    if [[ -z "$detected_user" ]]; then
        detected_user="$(whoami)"
    fi
    
    echo "$detected_user"
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
    log_info "Checking for available updates..."
    
    echo -e "\n${BLUE}=== PLUGIN UPDATES ===${NC}"
    PLUGIN_UPDATES=$(wp plugin list --fields=name,status,update,version,update_version --allow-root --format=csv 2>/dev/null | grep "available" || true)
    
    if [[ -n "$PLUGIN_UPDATES" ]]; then
        echo "$PLUGIN_UPDATES" | while IFS= read -r line; do
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
    
    USERS_OUTPUT=$(wp user list --fields=ID,user_login,display_name,user_email,roles --allow-root 2>/dev/null || true)
    
    if [[ -n "$USERS_OUTPUT" ]]; then
        echo "ID | Username | Display Name | Email | Role"
        echo "---|----------|--------------|-------|------"
        echo "$USERS_OUTPUT" | tail -n +2
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
FIX_PERMISSIONS=true
VERBOSE=false
WP_PATH=""
CUSTOM_USER=""
CUSTOM_GROUP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -u=*|--user=*)
            CUSTOM_USER="${1#*=}"
            shift
            ;;
        -g=*|--group=*)
            CUSTOM_GROUP="${1#*=}"
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

# Auto-detect web user if not specified
if [[ -n "$CUSTOM_USER" ]]; then
    WP_USER="$CUSTOM_USER"
else
    WP_USER=$(detect_web_user)
fi

if [[ -n "$CUSTOM_GROUP" ]]; then
    WP_GROUP="$CUSTOM_GROUP"
else
    WP_GROUP="$WP_USER"
fi

# Set default path if not provided
WP_PATH="${WP_PATH:-$(pwd)}"
WP_PATH="${WP_PATH%/}"

log_info "Starting WordPress repair process..."
log_info "WordPress path: $WP_PATH"
log_info "Using user: $WP_USER"
log_info "Using group: $WP_GROUP"

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
# 2. Fix permissions (optional) - ВИПРАВЛЕНО!
# -------------------------
if [[ "$FIX_PERMISSIONS" == true ]]; then
    log_info "Fixing permissions..."
    
    # Логіка зміни власності - ВИПРАВЛЕНО
    if [[ "$WP_USER" == "$(whoami)" ]]; then
        log_info "User is current user ($WP_USER), skipping ownership change"
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
log_info "Detecting WordPress version..."
WP_VERSION=$(wp core version --allow-root 2>/dev/null || true)

if [[ -z "$WP_VERSION" ]]; then
    log_error "Cannot detect WP version via WP-CLI"
    log_info "Trying alternative method..."
    
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
# 4. Backup wp-content and wp-config - ВИПРАВЛЕНО!
# -------------------------
# Бекап в поточній директорії
BACKUP_DIR="$WP_PATH/wp-backup-$(date +%Y%m%d-%H%M%S)"
log_info "Creating backup in: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"
if cp -a wp-config.php "$BACKUP_DIR/" 2>/dev/null; then
    log_info "wp-config.php backed up"
else
    log_warn "Could not backup wp-config.php"
fi

if [[ -d "wp-content" ]]; then
    if cp -a wp-content "$BACKUP_DIR/" 2>/dev/null; then
        log_info "wp-content backed up"
    else
        log_warn "Could not backup wp-content"
    fi
fi

log_info "Backup created at: $BACKUP_DIR"

# -------------------------
# 5. Download clean core
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
    
    # Встановлюємо правильні права перед запаковуванням в кеш
    log_info "Setting correct permissions for downloaded files..."
    find "/tmp/wordpress-$WP_VERSION" -type d -exec chmod 755 {} \; 2>/dev/null
    find "/tmp/wordpress-$WP_VERSION" -type f -exec chmod 644 {} \; 2>/dev/null
    
    cd "/tmp/wordpress-$WP_VERSION" && zip -qr "$CACHE_FILE" . && cd - >/dev/null
    rm -rf "/tmp/wordpress-$WP_VERSION"
fi

log_info "Extracting core files..."
if unzip -q -o "$CACHE_FILE" -d "$WP_PATH" 2>/dev/null; then
    log_info "Core files extracted"
    
    # Встановлюємо права після розпаковки
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
if [[ -d "$BACKUP_DIR/wp-content" ]]; then
    if cp -a "$BACKUP_DIR/wp-content/." "wp-content/" 2>/dev/null; then
        log_info "wp-content restored"
    else
        log_warn "Could not restore wp-content"
    fi
fi

if [[ -f "$BACKUP_DIR/wp-config.php" ]]; then
    if cp -f "$BACKUP_DIR/wp-config.php" . 2>/dev/null; then
        log_info "wp-config.php restored"
    else
        log_warn "Could not restore wp-config.php"
    fi
fi

# Встановлюємо права для відновлених файлів
if [[ "$FIX_PERMISSIONS" == true ]]; then
    log_info "Setting permissions for restored files..."
    # Права для wp-config.php
    [[ -f "wp-config.php" ]] && chmod 640 wp-config.php 2>/dev/null && log_info "wp-config.php permissions set to 640"
    
    # Права для вмісту wp-content
    [[ -d "wp-content" ]] && set_permissions "wp-content"
fi

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
    
    for dir in wp-admin wp-includes; do
        if [[ -d "$dir" ]]; then
            SUSPICIOUS_FILES=$(find "$dir" -name "*.php" -type f ! -path "*/includes/*" ! -path "*/admin/*" \
                -exec grep -l "eval\|base64_decode\|gzinflate" {} \; 2>/dev/null || true)
            
            if [[ -n "$SUSPICIOUS_FILES" ]]; then
                echo "$SUSPICIOUS_FILES" | while read -r suspicious; do
                    log_warn "Removing suspicious file: $suspicious"
                    rm -f "$suspicious"
                done
            fi
        fi
    done
fi

# -------------------------
# 7. Run additional checks
# -------------------------
check_updates
list_users

# -------------------------
# 8. Final permissions check
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
# 9. Final cleanup - ВИПРАВЛЕНО!
# -------------------------
log_info "Cleaning up..."
log_info "Backup remains at: $BACKUP_DIR"
log_info "You can remove it manually when sure everything is OK:"
log_info "  rm -rf $BACKUP_DIR"

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
- Backup location: $BACKUP_DIR

Recommended next steps:
1. Clear browser cache
2. Update plugins and themes listed above
3. Review user list and remove unused accounts
4. Install security plugin like: ${YELLOW}$RANDOM_PLUGIN${NC}
5. Change all administrative passwords
6. Enable regular backups
7. Check .htaccess for suspicious code
8. Remove backup when verified: rm -rf $BACKUP_DIR

EOF

exit 0
