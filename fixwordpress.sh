#!/bin/bash

# ==================================================
#  Auto-detect WordPress + Repair Core via WP-CLI
# ==================================================

echo "[INFO] Searching for WordPress installations..."

# Find all WP installations — absolute paths + silent errors
mapfile -t WP_SITES < <(
    find . -type f -path "*/wp-includes/version.php" 2>/dev/null \
    | sed 's|/wp-includes/version.php||' \
    | xargs -I{} realpath {}
)

# Check if found any
if [[ ${#WP_SITES[@]} -eq 0 ]]; then
    echo "[ERROR] No WordPress installations found."
    exit 1
fi

echo
echo "Found WordPress installations:"
echo "==============================="
i=1
declare -a WP_DOMAINS
for SITE in "${WP_SITES[@]}"; do
    # Get domain directly from database via WP-CLI
    DOMAIN=$(wp option get siteurl --path="$SITE" --allow-root --skip-plugins --skip-themes 2>/dev/null)
    DOMAIN=${DOMAIN#*://}
    DOMAIN=${DOMAIN:-"UNKNOWN_DOMAIN"}
    WP_DOMAINS+=("$DOMAIN")
    echo "  $i) $DOMAIN — $SITE"
    ((i++))
done
echo "==============================="
echo

# Ask user to choose installation
read -p "Select the number of installation to repair: " SELECTED

if ! [[ "$SELECTED" =~ ^[0-9]+$ ]] || (( SELECTED < 1 || SELECTED > ${#WP_SITES[@]} )); then
    echo "[ERROR] Invalid selection."
    exit 1
fi

# Selected path and domain
WP_PATH="${WP_SITES[$((SELECTED-1))]}"
WP_DOMAIN="${WP_DOMAINS[$((SELECTED-1))]}"
echo "[INFO] Selected WordPress directory: $WP_PATH"
echo "[INFO] Domain: $WP_DOMAIN"
echo

# ==================================================
#  STEP 1 — Fix permissions (before repair)
# ==================================================
echo "[INFO] Fixing initial permissions..."

find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

if id "www-data" &>/dev/null; then
    chown -R www-data:www-data "$WP_PATH"
fi

echo "[OK] Initial permissions fixed."

# ==================================================
#  STEP 2 — Detect WP version via WP-CLI
# ==================================================
WP_VERSION=$(wp core version --path="$WP_PATH" --allow-root --skip-plugins --skip-themes)

if [[ -z "$WP_VERSION" ]]; then
    echo "[ERROR] Cannot detect WordPress version. Is WP-CLI working?"
    exit 1
fi

echo "[INFO] Detected WP version: $WP_VERSION"

# ==================================================
#  STEP 3 — Download clean WordPress core
# ==================================================
echo "[INFO] Downloading clean WordPress core $WP_VERSION..."

# Use custom cache folder in the site directory to avoid global .cli
export WP_CLI_CACHE_DIR="$WP_PATH/.wp-cli-cache"

wp core download \
    --version="$WP_VERSION" \
    --force \
    --skip-content \
    --allow-root \
    --skip-plugins \
    --skip-themes \
    --path="$WP_PATH"

echo "[OK] Core files replaced with clean version."

# ==================================================
#  STEP 4 — Verify core integrity
# ==================================================
echo "[INFO] Verifying WordPress core checksums..."

wp core verify-checksums --path="$WP_PATH" --allow-root --skip-plugins --skip-themes

echo "[OK] Core integrity verified."

# ==================================================
#  STEP 5 — Fix permissions (after repair)
# ==================================================
echo "[INFO] Fixing final permissions..."

find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

if id "www-data" &>/dev/null; then
    chown -R www-data:www-data "$WP_PATH"
fi

echo
echo "[DONE] WordPress core repaired, verified and permissions fixed."
echo
