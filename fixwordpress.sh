#!/bin/bash

# WordPress directory (default = current directory)
WP_PATH="${1:-$(pwd)}"

echo "[INFO] WordPress path: $WP_PATH"

cd "$WP_PATH" || {
  echo "[ERROR] Cannot enter directory."
  exit 1
}

# -------------------------
# 1. Fix permissions
# -------------------------
echo "[INFO] Fixing permissions..."

find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

if id "www-data" &>/dev/null; then
    chown -R www-data:www-data "$WP_PATH"
fi

echo "[OK] Permissions fixed."


# -------------------------
# 2. Detect WP version
# -------------------------
WP_VERSION=$(wp core version --allow-root)

if [[ -z "$WP_VERSION" ]]; then
    echo "[ERROR] Cannot detect WP version (wp-cli not working?)."
    exit 1
fi

echo "[INFO] Detected WP version: $WP_VERSION"


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
# 4. Extra: Verify core integrity (optional)
# -------------------------
echo "[INFO] Checking WordPress core integrity..."

wp core verify-checksums --allow-root

echo "[DONE] WordPress core repaired and verified."
