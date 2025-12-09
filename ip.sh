#!/bin/bash
# firewall_shared.sh
# Аналіз логів WordPress на shared hosting
# Виводить IP атак і підмережі з кількістю запитів

LOG_DIR="$HOME/logs"   # зміни на свій каталог логів
ATTACK_LOG="$HOME/wp_attacks.log"

# Підозрілі патерни
PATTERNS="wp-login.php|xmlrpc.php|wp-content|wp-includes|plugins|themes|\.php|\.tmb|uploads|maintenance"

echo "======================================"
echo "🔍 Аналіз логів на підозрілі запити WordPress"
echo "======================================"

# Очистити лог атаки перед запуском
> "$ATTACK_LOG"

# --- Обробка архівів .gz ---
find "$LOG_DIR" -type f -name "*.gz" | while read LOGFILE; do
    echo "➡ Аналіз архіву: $LOGFILE"
    gunzip -c "$LOGFILE" | \
    grep -E "$PATTERNS" | \
    awk '{print $1}' >> "$ATTACK_LOG"
done

# --- Обробка звичайних логів ---
find "$LOG_DIR" -type f -name "*.log" | while read LOGFILE; do
    echo "➡ Аналіз звичайного лог файлу: $LOGFILE"
    grep -E "$PATTERNS" "$LOGFILE" | \
    awk '{print $1}' >> "$ATTACK_LOG"
done

# --- Підрахунок IP ---
echo ""
echo "📊 Підрахунок унікальних IP:"
sort "$ATTACK_LOG" | uniq -c | sort -nr

# --- Групування по підмережах /24 ---
echo ""
echo "🌐 Підмережі /24:"
awk -F. '{print $1"."$2"."$3}' "$ATTACK_LOG" | sort | uniq -c | sort -nr
