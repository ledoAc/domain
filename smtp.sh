#!/bin/bash
# wp_smtp_info_njq.sh
# Виводить ключові налаштування SMTP WordPress без jq

# Перевірка наявності wp-cli
if ! command -v wp &>/dev/null; then
    echo "❌ wp-cli не знайдено"
    exit 1
fi

# Отримуємо JSON
SMTP_JSON=$(wp option get wp_mail_smtp --format=json)

if [ -z "$SMTP_JSON" ]; then
    echo "⚠️ Налаштування wp_mail_smtp не знайдено"
    exit 0
fi

# --- Витягаємо ключові поля ---
FROM_EMAIL=$(echo "$SMTP_JSON" | grep -o '"from_email":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
FROM_NAME=$(echo "$SMTP_JSON" | grep -o '"from_name":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
SMTP_HOST=$(echo "$SMTP_JSON" | grep -o '"host":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
SMTP_PORT=$(echo "$SMTP_JSON" | grep -o '"port":[0-9]*' | head -1 | cut -d':' -f2)
SMTP_ENC=$(echo "$SMTP_JSON" | grep -o '"encryption":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
SMTP_USER=$(echo "$SMTP_JSON" | grep -o '"user":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
SMTP_PASS=$(echo "$SMTP_JSON" | grep -o '"pass":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')

# --- Вивід ---
echo "======================================"
echo "🔹 Налаштування SMTP WordPress"
echo "======================================"
echo "SMTP сервер:       $SMTP_HOST"
echo "SMTP порт:         $SMTP_PORT"
echo "Шифрування:        $SMTP_ENC"
echo "Login (username):  $SMTP_USER"
echo "Pass (username):  $SMTP_PASS"
echo "Email відправника: $FROM_EMAIL"
echo "Ім'я відправника:  $FROM_NAME"
echo "======================================"
