#!/bin/bash

# --- COLORS ---
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

echo -e "${YELLOW}Перевіряю WordPress checksums...${RESET}"
CHECKSUM_OUTPUT=$(wp core verify-checksums 2>&1)

echo -e "$CHECKSUM_OUTPUT" | while read -r line; do
    if [[ "$line" == *"doesn't verify against checksum"* ]]; then
        echo -e "${RED}$line${RESET}"
        echo -e "${YELLOW}Пояснення:${RESET} Файл змінено або заражено. Порівняння з оригінальним WP не співпадає."
        echo ""
    elif [[ "$line" == *"should not exist"* ]]; then
        echo -e "${RED}$line${RESET}"
        echo -e "${YELLOW}Пояснення:${RESET} Цей файл не є частиною WordPress. Ймовірно хтось додав його вручну або це наслідок зламу."
        echo ""
    elif [[ "$line" == *"Error:"* ]]; then
        echo -e "${RED}$line${RESET}"
        echo -e "${YELLOW}Пояснення:${RESET} Основні файли WordPress не відповідають оригінальним. Потрібно замінити їх на чисті."
        echo ""
    else
        echo "$line"
    fi
done


echo -e "${YELLOW}Перевіряю права доступу на файли...${RESET}"

echo ""
echo -e "${YELLOW}Файли (має бути 644):${RESET}"
find ./ -type f ! -perm 644 -print -exec echo -e "${RED}Невірні права${RESET}. Рекомендовано: 644" \;

echo ""
echo -e "${YELLOW}Папки (має бути 755):${RESET}"
find ./ -type d ! -perm 755 -print -exec echo -e "${RED}Невірні права${RESET}. Рекомендовано: 755" \;

echo ""
echo -e "${GREEN}Перевірка завершена.${RESET}"
