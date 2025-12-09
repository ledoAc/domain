#!/bin/bash

LOG_DIR="/home/$USER/logs"

echo "🔍 Сканую архіви логів..."

# Обробка всіх .gz логів
find "$LOG_DIR" -type f -name "*.gz" | while read LOGFILE; do
    echo "➡ Аналіз: $LOGFILE"
    gunzip -c "$LOGFILE" | \
        grep -E "wp-content|wp-includes|wp-login|\.php|plugins|themes" | \
        awk '{print $1}' | \
        sort | uniq -c | sort -nr
done

# Обробка звичайних логів
echo "🔍 Сканую звичайні логи..."
find "$LOG_DIR" -type f -name "*.log" | while read LOGFILE; do
    echo "➡ Аналіз: $LOGFILE"
    grep -E "wp-content|wp-includes|wp-login|\.php|plugins|themes" "$LOGFILE" | \
        awk '{print $1}' | \
        sort | uniq -c | sort -nr
done
