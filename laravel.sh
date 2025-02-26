#!/bin/bash
clear

RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
NC='\e[0m' 
LIGHT_GREEN='\033[1;32m'
ORANGE='\e[38;5;214m'
ROOT_DIR="$(pwd)"


echo -e "${LIGHT_GREEN}#################### Laravel troubleshooter ####################${NC}"

if [ ! -f artisan ]; then
    echo -e "${RED}Помилка: Схоже, що ви не знаходитеся в кореневій директорії Laravel.${NC}"
    exit 1
fi

while true; do
    
    echo -e "${BLUE}Оберіть команду для виконання:${NC}"
    echo -e "${YELLOW}1)${NC} Включити режим розробки"
    echo -e "${YELLOW}2)${NC} Вийти з режиму розробки"
    echo -e "${YELLOW}3)${NC} Інформація про додаток"
    echo -e "${YELLOW}4)${NC} Очистити кеш"
    echo -e "${YELLOW}5)${NC} Моніторинг бази даних"
    echo -e "${YELLOW}6)${NC} Показати інформацію про БД"
    echo -e "${YELLOW}7)${NC} Генерувати ключ додатку"
    echo -e "${YELLOW}8)${NC} Включити DEBUG mode"
    echo -e "${YELLOW}9)${NC} Вимкнути DEBUG mode"
    echo -e "${YELLOW}10)${NC} Показати налаштування бази з .env"
    echo -e "${YELLOW}11)${NC} Перевірити права доступу"
    echo -e "${YELLOW}12)${NC} Виправити права доступу"
    echo -e "${YELLOW}13)${NC} Вийти"

    read -p "Введіть номер команди: " choice

    case $choice in
        1)
            echo -e "${GREEN}Перевірка......${NC}"
            php artisan down
            ;;
        2)
            echo -e "${GREEN}Перевірка......${NC}"
            php artisan up
            ;;
        3)
            echo -e "${GREEN}Перевірка......${NC}"
            php artisan about
            ;;
        4)
            echo -e "${GREEN}Перевірка......${NC}"
            php artisan cache:clear
            ;;
        5)
            echo -e "${GREEN}Перевірка......${NC}"
            php artisan db:monitor
            ;;
        6)
            echo -e "${GREEN}Перевірка......${NC}"
            php artisan db:show
            ;;
        7)
            echo -e "${GREEN}Перевірка......${NC}"
            php artisan key:generate
            ;;
        8)
            echo -e "${GREEN}Включаємо debug mode${NC}"
            sed -i 's/APP_DEBUG=.*/APP_DEBUG=true/' .env && php artisan config:clear
            echo -e "${ORANGE}Дебаг мод включено успішно${NC}"
            ;;
        9)
            echo -e "${GREEN}Вимикаємо debug mode${NC}"
            sed -i 's/APP_DEBUG=.*/APP_DEBUG=false/' .env && php artisan config:clear
            echo -e "${ORANGE}Дебаг мод виключено успішно${NC}"
            ;;
        10)  
            echo -e "${GREEN}Налаштування бази даних:${NC}"
            grep -E 'DB_HOST|DB_DATABASE|DB_USERNAME|DB_PASSWORD' .env
            ;;
        11)
           echo -e "${BLUE}Перевірка дозволів файлів та папок у $ROOT_DIR...${NC}"
            find "$ROOT_DIR" -type d ! -perm 755 -exec echo -e "${RED}Папка з некоректними дозволами: {}${NC}" \;
            find "$ROOT_DIR" -type f ! -perm 644 -exec echo -e "${RED}Файл з некоректними дозволами: {}${NC}" \;
            ;;
        12)
            echo -e "${BLUE}Виправлення дозволів файлів та папок у $ROOT_DIR...${NC}"
            find "$ROOT_DIR" -type d ! -perm 755 -exec chmod 755 {} \;
            find "$ROOT_DIR" -type f ! -perm 644 -exec chmod 644 {} \;
            echo -e "${GREEN}Виправлення завершено!${NC}"
            ;;
        13)
            echo -e "${RED}Вихід...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Невірний вибір, спробуйте ще раз.${NC}"
            ;;
     esac

    echo ""
    read -p "Натисніть Enter для продовження..." 
done
