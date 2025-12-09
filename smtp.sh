#!/bin/bash
# wp_smtp_universal.sh
# Виводить налаштування SMTP для всіх плагінів WordPress

# Перевірка наявності wp-cli
if ! command -v wp &>/dev/null; then
    echo "❌ wp-cli не знайдено"
    exit 1
fi

echo "======================================"
echo "🔹 Перевірка налаштувань SMTP WordPress"
echo "======================================"

# Знаходимо всі опції, що містять 'smtp' або 'mail'
OPTIONS=$(wp option list --search=smtp --format=csv | tail -n +2)

if [ -z "$OPTIONS" ]; then
    echo "⚠️ SMTP-плагіни не знайдено"
    exit 0
fi

# Проходимо по всіх опціях
for opt in $OPTIONS; do
    echo ""
    echo "🔹 Опція плагіна: $opt"
    JSON=$(wp option get "$opt" --format=json)
    if [ -z "$JSON" ]; then
        echo "⚠️ Налаштування пусті"
        continue
    fi

    # Витягаємо ключові поля (Bash парсинг JSON без jq)
    FROM_EMAIL=$(echo "$JSON" | grep -o '"from_email":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
    FROM_NAME=$(echo "$JSON" | grep -o '"from_name":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
    SMTP_HOST=$(echo "$JSON" | grep -o '"host":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
    SMTP_PORT=$(echo "$JSON" | grep -o '"port":[0-9]*' | head -1 | cut -d':' -f2)
    SMTP_ENC=$(echo "$JSON" | grep -o '"encryption":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')
    SMTP_USER=$(echo "$JSON" | grep -o '"user":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')

    echo "SMTP сервер:       ${SMTP_HOST:-не задано}"
    echo "SMTP порт:         ${SMTP_PORT:-не задано}"
    echo "Шифрування:        ${SMTP_ENC:-не задано}"
    echo "Логін (username):  ${SMTP_USER:-не задано}"
    echo "Email відправника: ${FROM_EMAIL:-не задано}"
    echo "Ім'я відправника:  ${FROM_NAME:-не задано}"
done

echo ""
echo "======================================"
echo "✅ Перевірка SMTP завершена."
echo "======================================"
