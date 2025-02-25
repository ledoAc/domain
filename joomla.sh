#!/bin/bash

ERROR_LOG="error_log"
CLI_PATH="cli/joomla.php"
ROOT_DIR="$(pwd)"

RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[96m'
NC='\e[0m'

chmod +x "$CLI_PATH"

while true; do
    clear
    echo -e "${BLUE}Виберіть команду для виконання:${NC}"
    echo -e "${YELLOW}1)${NC} Оновлення ядра Joomla"
    echo -e "${YELLOW}2)${NC} Перегляд списку розширень"
    echo -e "${YELLOW}3)${NC} Індексація контенту Finder (оновлює пошукову базу для швидкого пошуку)"
    echo -e "${YELLOW}4)${NC} Обслуговування бази даних (перевірка та виправлення помилок БД)"
    echo -e "${YELLOW}5)${NC} Очищення сесій (видаляє застарілі сесії для оптимізації роботи)"
    echo -e "${YELLOW}6)${NC} Переключити на сайті режим обслуговування"
    echo -e "${YELLOW}7)${NC} Виключити на сайті режим обслуговування"
    echo -e "${YELLOW}8)${NC} Список користувачів"
    echo -e "${YELLOW}9)${NC} Додати користувача"
    echo -e "${YELLOW}10)${NC} Скидання пароля користувача"
    echo -e "${YELLOW}11)${NC} Переглянути error_log"
    echo -e "${YELLOW}12)${NC} Перевірити дозволи на файли та папки"
    echo -e "${YELLOW}13)${NC} Виправити дозволи файлів та папок"
    echo -e "${YELLOW}14)${NC} Очищення кешу Joomla"
    echo -e "${RED}0)${NC} Вийти"
    echo ""
    read -p "Введіть номер опції: " choice

    case $choice in
        1) php "$CLI_PATH" core:update ;;
        2) php "$CLI_PATH" extension:list ;;
        3) php "$CLI_PATH" finder:index ;;
        4) php "$CLI_PATH" maintenance:database ;;
        5) php "$CLI_PATH" session:gc ;;
        6) php "$CLI_PATH" site:down ;;
        7) php "$CLI_PATH" site:up ;;
        8) php "$CLI_PATH" user:list ;;
        9) php "$CLI_PATH" user:add ;;
        10) php "$CLI_PATH" user:reset-password ;;
        11)
            if [ -f "$ERROR_LOG" ]; then
                echo -e "${BLUE}Помилки з error_log:${NC}"
                tail -n 5 "$ERROR_LOG"
            else
                echo -e "${RED}Файл error_log не знайдено!${NC}"
            fi
            ;;
        12)
            echo -e "${BLUE}Перевірка дозволів файлів та папок у $ROOT_DIR...${NC}"
            find "$ROOT_DIR" -type d ! -perm 755 -exec echo -e "${RED}Папка з некоректними дозволами: {}${NC}" \;
            find "$ROOT_DIR" -type f ! -perm 644 -exec echo -e "${RED}Файл з некоректними дозволами: {}${NC}" \;
            ;;
        13)
            echo -e "${BLUE}Виправлення дозволів файлів та папок у $ROOT_DIR...${NC}"
            find "$ROOT_DIR" -type d ! -perm 755 -exec chmod 755 {} \;
            find "$ROOT_DIR" -type f ! -perm 644 -exec chmod 644 {} \;
            echo -e "${GREEN}Виправлення завершено!${NC}"
            ;;
        14) php "$CLI_PATH" cache:clean | tee -a "$LOG_FILE" ;;
               0) echo -e "${RED}Вихід...${NC}"; exit 0 ;;
        *) echo -e "${RED}Невірний вибір, спробуйте ще раз.${NC}"; sleep 2 ;;
    esac

    echo ""
    read -p "Натисніть Enter для продовження..." 

done
