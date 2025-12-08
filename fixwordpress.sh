#!/bin/bash

# WordPress directory (default = current directory)
WP_PATH="${1:-$(pwd)}"

echo "[INFO] WordPress path: $WP_PATH"

cd "$WP_PATH" || {
  echo "[ERROR] Cannot enter directory."
  exit 1
}

# -------------------------
# 1. Initial permissions fix
# -------------------------
echo "[INFO] Fixing initial permissions..."

find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

if id "www-data" &>/dev/null; then
    chown -R www-data:www-data "$WP_PATH"
fi

echo "[OK] Initial permissions fixed."


# -------------------------
# 2. Detect WP version
# -------------------------
WP_VERSION=$(wp core version --allow-root)

if [[ -z "$WP_VERSION" ]]; then
    echo "[ERROR] Cannot detect WP version (wp-cli not working?)."
    exit 1
fi

echo "[INFO] Detected WordPress version: $WP_VERSION"


# -------------------------
# 3. Download clean core for this version
# -------------------------
echo "[INFO] Downloading core files for version $WP_VERSION..."

wp core download \
    --version="$WP_VERSION" \
    --force \
    --skip-content \
    --allow-root

echo "[OK] Core files updated to clean version."


# -------------------------
# 4. Verify core integrity
# -------------------------
echo "[INFO] Checking WordPress core integrity..."

wp core verify-checksums --allow-root

echo "[OK] Core verification complete."


# -------------------------
# 5. Fix permissions again after core update
# -------------------------
echo "[INFO] Fixing permissions again after core update..."

find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

if id "www-data" &>/dev/null; then
    chown -R www-data:www-data "$WP_PATH"
fi

echo "[DONE] WordPress core repaired, verified, and permissions fixed."
