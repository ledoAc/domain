#!/bin/bash
# elementor_fix_full.sh
# Комплексний скрипт ремонту Elementor для WordPress

# Налаштування
WP_PATH="$HOME/public_html"                  # шлях до WordPress
ELEMENTOR_DIR="$WP_PATH/wp-content/plugins/elementor"
ELEMENTOR_CACHE="$WP_PATH/wp-content/uploads/elementor"
USER_NAME="$USER"                             # зміни, якщо потрібно інший користувач
MIN_MEMORY="128M"
MIN_EXEC="60"
MIN_UPLOAD="32M"
MIN_POST="32M"

echo "======================================"
echo "🔧 Запуск комплексного ремонту Elementor"
echo "======================================"

# --- Перевірка директорії Elementor ---
if [ -d "$ELEMENTOR_DIR" ]; then
    echo "✅ Директорія Elementor знайдена: $ELEMENTOR_DIR"
else
    echo "❌ Директорія Elementor не знайдена!"
    exit 1
fi

# --- Виправлення прав та власника ---
echo "🔹 Виправляємо права файлів і папок..."
find "$ELEMENTOR_DIR" -type f -exec chmod 644 {} \;
find "$ELEMENTOR_DIR" -type d -exec chmod 755 {} \;
chown -R $USER_NAME:$USER_NAME "$ELEMENTOR_DIR"
echo "✅ Права та власник виправлено."

# --- Очищення кешу Elementor ---
if [ -d "$ELEMENTOR_CACHE" ]; then
    echo "🔹 Очищення кешу Elementor..."
    rm -rf "$ELEMENTOR_CACHE/*"
    echo "✅ Кеш очищено."
else
    echo "⚠️ Кеш директорія не знайдена, пропускаємо."
fi

# --- Версії Elementor та WordPress ---
PLUGIN_FILE="$ELEMENTOR_DIR/elementor.php"
if [ -f "$PLUGIN_FILE" ]; then
    ELEMENTOR_VERSION=$(grep "Version:" "$PLUGIN_FILE" | awk '{print $2}')
    echo "🔹 Elementor версія: $ELEMENTOR_VERSION"
else
    echo "❌ Файл elementor.php не знайдено!"
fi

if command -v wp &>/dev/null; then
    WP_VERSION=$(wp core version --path="$WP_PATH")
    echo "🔹 WordPress версія: $WP_VERSION"
else
    echo "⚠️ wp-cli не знайдено, пропускаємо перевірку WP версії."
fi

# --- Перевірка PHP лімітів ---
MEMORY_LIMIT=$(php -r "echo ini_get('memory_limit');")
MAX_EXECUTION=$(php -r "echo ini_get('max_execution_time');")
UPLOAD_LIMIT=$(php -r "echo ini_get('upload_max_filesize');")
POST_LIMIT=$(php -r "echo ini_get('post_max_size');")

echo ""
echo "💾 PHP ліміти:"
echo "memory_limit: $MEMORY_LIMIT"
echo "max_execution_time: $MAX_EXECUTION"
echo "upload_max_filesize: $UPLOAD_LIMIT"
echo "post_max_size: $POST_LIMIT"

# --- Рекомендації ---
echo ""
echo "💡 Рекомендації:"
[[ ${MEMORY_LIMIT%M} -lt ${MIN_MEMORY%M} ]] && echo "⚠️ Рекомендується memory_limit ≥ $MIN_MEMORY"
[[ $MAX_EXECUTION -lt $MIN_EXEC ]] && echo "⚠️ Рекомендується max_execution_time ≥ $MIN_EXEC"
[[ ${UPLOAD_LIMIT%M} -lt ${MIN_UPLOAD%M} ]] && echo "⚠️ Рекомендується upload_max_filesize ≥ $MIN_UPLOAD"
[[ ${POST_LIMIT%M} -lt ${MIN_POST%M} ]] && echo "⚠️ Рекомендується post_max_size ≥ $MIN_POST"

echo "======================================"
echo "✅ Ремонт Elementor завершено."
echo "======================================"
