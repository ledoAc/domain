#!/bin/bash
clear
# Визначення шляху до сайту
SITE_PATH="$(pwd)"

# Отримання версії WordPress
if [[ -f "$SITE_PATH/wp-includes/version.php" ]]; then
    WP_VERSION=$(grep -oP "\$wp_version = '\K[^']+" "$SITE_PATH/wp-includes/version.php")
    echo "WordPress версія: $WP_VERSION"
else
    echo "Файл версії WordPress не знайдено!"
fi

# Пошук останнього зміненого лог-файлу
LOG_DIR="$SITE_PATH/logs"
LAST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -n 1)

if [[ -n "$LAST_LOG" ]]; then
    echo "Останній лог-файл: $LAST_LOG"
    echo "Останній рядок логу:"
    tail -n 1 "$LAST_LOG"
else
    echo "Лог-файли не знайдено!"
fi
