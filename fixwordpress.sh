#!/bin/bash

# =============================
#   AUTO-DETECT WORDPRESS + FIX
# =============================

echo "[INFO] Searching for WordPress installations..."

# Знаходимо всі wp-includes/version.php (ознака WP)
mapfile -t WP_SITES < <(find . -type f -path "*/wp-includes/version.php" | sed 's|/wp-includes/version.php||')

if [[ ${#WP_SITES[@]} -eq 0 ]]; then
    echo "[ERROR] No WordPress installations found."
    exit 1
fi

echo
echo "Found WordPress installations:"
echo "==============================="
i=1
for SITE in "${WP_SITES[@]}"; do
    echo "  $i) $SITE"
    ((i++))
done
echo "==============================="
echo

# Вибір папки
read -p "Select the number of the WordPress installation to repair: " SELECTED

if ! [[ "$SELECTED" =~ ^[0-9]+$ ]] || (( SELECTED < 1 || SELECTED > ${#WP_SITES[@]} )); then
    echo "[ERROR] Invalid selection."
    exit 1
fi

WP_PATH="${WP_SITES[$((SELECTED-1))]}"
echo "[INFO] Selected: $WP_PATH"
echo

# Переходимо в WP директорію
cd "$WP_PATH" || {
    echo "[ERROR] Cannot enter selected directory."
    exit 1
}

# =============================
#   ORIGINAL FIX SCRIPT BELOW
# =============================

echo "[INFO] Fixing initial permissions..."

find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

if id "www-data" &>/dev/null; then
    chown -R www-data:www-data "$WP_PATH"
fi

echo "[OK] Initial permissions fixed."

# Detect version
WP_VERSION=$(wp core version --allow-root)

if [[ -z "$WP_VERSION" ]]; then
    echo "[ERROR] Cannot detect WP version. Is wp-cli installed?"
    exit 1
fi

echo "[INFO] Detected WordPress version: $WP_VERSION"

# Download clean core
echo "[INFO] Downloading clean core $WP_VERSION..."
wp core download --version="$WP_VERSION" --force --skip-content --allow-root
echo "[OK] Core files updated."

# Verify checksums
echo "[INFO] Verifying core integrity..."
wp core verify-checksums --allow-root
echo "[OK] Checksum verified."

# Fix perms again
echo "[INFO] Fixing permissions again after update..."

find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

if id "www-data" &>/dev/null; then
    chown -R www-data:www-data "$WP_PATH"
fi

echo "[DONE] WordPress core repaired and permissions fixed."
