#!/bin/bash

# ------------------------------------------------------
#  WordPress File Integrity + Permissions Check Script
#  Author: ledoAc
#  Version: 1.0
# ------------------------------------------------------

CHECKSUM_URL="https://raw.githubusercontent.com/ledoAc/domain/main/checksums"

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
printf "%-60s | %-10s | %s\n" "Файл" "Статус" "Пояснення"
printf "%.0s-" {1..100}; echo

while read -r file hash; do
    [[ -z "$file" || -z "$hash" ]] && continue

    if [[ -f "$file" ]]; then
        current_hash=$(sha256sum "$file" | awk '{print $1}')
        if [[ "$current_hash" != "$hash" ]]; then
            printf "%-60s | %-10s | %s\n" "$file" "BAD" "Хеш не співпадає"
        else
            printf "%-60s | %-10s | %s\n" "$file" "OK" ""
        fi
    else
        printf "%-60s | %-10s | %s\n" "$file" "MISSING" "Файл відсутній"
    fi
done < "$TMP_FILE"


echo
echo "=============================================="
echo " 🔍 ПЕРЕВІРКА НЕПРАВИЛЬНИХ ПРАВ ДОСТУПУ"
echo "=============================================="
printf "%-60s | %-10s | %-10s\n" "Файл/Папка" "Поточні" "Повинні"
printf "%.0s-" {1..90}; echo

while IFS= read -r path; do
    if [[ -f "$path" ]]; then
        expected="644"
    elif [[ -d "$path" ]]; then
        expected="755"
    else
        continue
    fi

    current=$(stat -c "%a" "$path")

    if [[ "$current" != "$expected" ]]; then
        printf "%-60s | %-10s | %-10s\n" "$path" "$current" "$expected"
    fi
done < <(find . -type f -o -type d)

echo
echo "✅ Перевірка завершена"
