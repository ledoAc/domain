#!/bin/bash

# Отримуємо поточний шлях
wp_path=$(pwd)

# Зчитування версії WordPress
if [ -f "$wp_path/wp-includes/version.php" ]; then
    version=$(grep "\$wp_version =" "$wp_path/wp-includes/version.php" | cut -d "'" -f 2)
else
    version="Не знайдено"
fi

# Колірні коди для форматування виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Функція для логування
log_message() {
    local message="$1"
    echo -e "$message"
}

# Виведення версії WordPress
log_message "${BLUE}Версія WordPress: $version${RESET}"

# Функція для перевірки прав доступу
check_permissions() {
    log_message "${GREEN}Перевірка папок та файлів з неправильними правами доступу...${RESET}"
    
    declare -A invalid_dirs
    declare -A invalid_files
    
    find ./ -type d | while read dir; do
        perms=$(stat -c "%a" "$dir")
        if [ "$perms" != "755" ]; then
            ((invalid_dirs[$dir]++))
        fi
    done

    find ./wp-content/plugins/ -type f | while read file; do
        perms=$(stat -c "%a" "$file")
        if [ "$perms" != "644" ]; then
            ((invalid_files[$file]++))
        fi
    done
    
    for dir in "${!invalid_dirs[@]}"; do
        log_message "${RED}$(basename "$dir"): ${invalid_dirs[$dir]} файлів з неправильними правами${RESET}"
    done
    
    for file in "${!invalid_files[@]}"; do
        log_message "${RED}$(basename "$file"): ${invalid_files[$file]} файлів з неправильними правами${RESET}"
    done
    
    if [ ${#invalid_dirs[@]} -eq 0 ] && [ ${#invalid_files[@]} -eq 0 ]; then
        log_message "${GREEN}Всі файли та папки мають правильні права доступу.${RESET}"
    fi
}

# Функція для отримання останнього рядка error_log і дати його модифікації
get_last_error_log() {
    error_log_file="./error_log"
    if [ -f "$error_log_file" ]; then
        last_modified=$(stat -c "%y" "$error_log_file")
        last_log=$(tail -n 1 "$error_log_file")
        log_message "${GREEN}Last Modified: $last_modified${RESET}"
        log_message "${GREEN}Останній рядок з error_log: $last_log${RESET}"
    else
        log_message "${RED}Файл error_log не знайдений.${RESET}"
    fi
}

# Викликаємо перевірки
check_permissions
get_last_error_log

# Запит на вибір дії
echo -e "${YELLOW}Обери дію:${RESET}"
echo "1. Виправити права доступу"
echo "2. Відключити плагіни та .htaccess"
echo "3. Замінити дефолтні файли WordPress"
read -p "Введіть номер вибору (1/2/3): " choice

case $choice in
    1)
        log_message "${GREEN}Виправлення прав доступу...${RESET}"
        find ./wp-content/plugins/ -type d -exec chmod 755 {} \;
        find ./wp-content/plugins/ -type f -exec chmod 644 {} \;
        log_message "${GREEN}Права доступу виправлено.${RESET}"
        ;;
    2)
        log_message "${GREEN}Відключення плагінів та .htaccess...${RESET}"
        mv ./wp-content/plugins ./wp-content/plugins_disabled
        mv ./.htaccess ./.htaccess_disabled
        log_message "${GREEN}Плагіни та .htaccess відключено.${RESET}"
        ;;
    3)
        read -p "Введіть версію WordPress (наприклад, 6.4.3): " wp_version
        log_message "${GREEN}Замінювання дефолтних файлів WordPress на версію $wp_version...${RESET}"
        wp core download --force --version=$wp_version
        log_message "${GREEN}Дефолтні файли WordPress замінено.${RESET}"
        ;;
    *)
        log_message "${RED}Невірний вибір!${RESET}"
        ;;
esac
