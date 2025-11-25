#!/bin/bash

# URL файлу зі списком хешів (GitHub raw)
CHECKSUM_URL="https://raw.githubusercontent.com/ledoAc/domain/main/checksums"

# Тимчасовий файл
TMP_FILE="/tmp/checksums.txt"

echo "Завантаження списку хешів..."
curl -s "$CHECKSUM_URL" -o "$TMP_FILE"

if [[ ! -s "$TMP_FILE" ]]; then
    echo "❌ Помилка: не вдалося завантажити checksums (файл порожній або не існує)."
    exit 1
fi

echo
echo "=============================================="
echo " 🔍 ПЕРЕВІРКА ХЕШІВ ФАЙЛІВ (CHECKSUMS)"
echo "=============================================="

# Колірні коди
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

while read -r file hash; do
    [[ -z "$file" || -z "$hash" ]] && continue

    if [[ -f "$file" ]]; then
        current_hash=$(sha256sum "$file" | awk '{print $1}')
        if [[ "$current_hash" != "$hash" ]]; then
            echo -e "${RED}BAD${RESET}    $file → Хеш не співпадає"
        else
            echo -e "${GREEN}OK${RESET}     $file"
        fi
    else
        echo -e "${RED}MISSING${RESET} $file → Файл відсутній"
    fi
done < "$TMP_FILE"

echo
echo "✅ Перевірка завершена"
