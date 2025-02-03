#!/bin/bash

# Отримуємо поточний шлях
wp_path=$(pwd)

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

# Перевірка на наявність файлу version.php
if [ -f "$wp_path/wp-includes/version.php" ]; then
    version=$(grep "\$wp_version =" "$wp_path/wp-includes/version.php" | cut -d "'" -f 2)
    log_message "${BLUE}Версія WordPress: $version${RESET}"
else
    log_message "${YELLOW}Файл version.php не знайдений. ${RESET}"
fi

# Перевірка на наявність оновлень WordPress
check_wordpress_update() {
    log_message "${GREEN}Перевірка на наявність оновлень WordPress...${RESET}"

    # Перевіряємо, чи є нові оновлення за допомогою WP-CLI
    if command -v wp &> /dev/null; then
        wp core check-update
    else
        log_message "${RED}WP-CLI не знайдений. Оновлення неможливо перевірити.${RESET}"
    fi
}

# Перевірка на помилки бази даних
check_database_errors() {
    log_message "${GREEN}Перевірка помилок бази даних...${RESET}"

    # Перевіряємо базу даних на помилки за допомогою WP-CLI
    if command -v wp &> /dev/null; then
        wp db check
    else
        log_message "${RED}WP-CLI не знайдений. Перевірка бази даних неможлива.${RESET}"
    fi
}

# Перевірка на наявність вразливих плагінів
check_vulnerable_plugins() {
    log_message "${GREEN}Перевірка плагінів на наявність вразливостей...${RESET}"

    # Для перевірки плагінів на вразливості можемо використовувати сторонні API або бази даних (наприклад, WPScan API)
    # Це може бути налаштовано як окремий скрипт для інтеграції з відповідними базами даних
    # Для цього прикладу виведемо повідомлення
    log_message "${YELLOW}Перевірка плагінів на вразливості не реалізована в даному скрипті.${RESET}"
}

# Перевірка кешування
check_caching() {
    log_message "${GREEN}Перевірка налаштувань кешування...${RESET}"

    # Перевірка наявності плагінів кешування та налаштувань на сервері
    if [ -d "$wp_path/wp-content/cache" ]; then
        log_message "${BLUE}Кешування увімкнене. Папка кешу: $wp_path/wp-content/cache${RESET}"
    else
        log_message "${YELLOW}Кешування не знайдено або вимкнене.${RESET}"
    fi
}

# Перевірка важливих URL-адрес
check_critical_urls() {
    log_message "${GREEN}Перевірка доступності важливих URL-адрес...${RESET}"

    # Перевіряємо доступність wp-login.php та wp-admin
    for url in "wp-login.php" "wp-admin"; do
        if curl -s -o /dev/null -w "%{http_code}" "$wp_path/$url" | grep -q "200"; then
            log_message "${GREEN}$url доступний.${RESET}"
        else
            log_message "${RED}$url недоступний.${RESET}"
        fi
    done
}

# Перевірка на наявність файлу .git
check_git_files() {
    log_message "${GREEN}Перевірка наявності файлів .git...${RESET}"

    # Перевіряємо наявність файлів .git в каталозі
    if [ -d "$wp_path/.git" ]; then
        log_message "${RED}Файл .git знайдений в каталозі. Рекомендується видалити його.${RESET}"
    else
        log_message "${GREEN}Файл .git не знайдений.${RESET}"
    fi
}

# Перевірка на налаштування безпеки
check_security_settings() {
    log_message "${GREEN}Перевірка налаштувань безпеки...${RESET}"

    # Перевірка на наявність плагінів безпеки
    if [ -d "$wp_path/wp-content/plugins" ]; then
        if [ -d "$wp_path/wp-content/plugins/wordfence" ]; then
            log_message "${GREEN}Плагін Wordfence знайдений. Безпека активована.${RESET}"
        else
            log_message "${YELLOW}Плагін Wordfence не знайдений. Рекомендується використовувати плагін для безпеки.${RESET}"
        fi
    else
        log_message "${RED}Папка плагінів не знайдена.${RESET}"
    fi
}

# Функція для перевірки прав доступу
check_permissions() {
    log_message "${GREEN}Перевірка папок та файлів з неправильними правами доступу...${RESET}"

    # Лічильники файлів та папок
    incorrect_files_count=0
    incorrect_folders_count=0

    # Перевіряємо файли з неправильними правами
    find "$wp_path" -type f | while read file; do
        perms=$(stat -c "%a" "$file")
        expected_perms="644"
        if [ "$perms" != "$expected_perms" ]; then
            log_message "${RED}Файл з неправильними правами доступу: $file (поточні: $perms, повинні бути: $expected_perms)${RESET}"
            incorrect_files_count=$((incorrect_files_count+1))
        fi
    done

    # Перевіряємо папки з неправильними правами
    find "$wp_path" -type d | while read dir; do
        perms=$(stat -c "%a" "$dir")
        expected_perms="755"
        if [ "$perms" != "$expected_perms" ]; then
            log_message "${RED}Папка з неправильними правами доступу: $dir (поточні: $perms, повинні бути: $expected_perms)${RESET}"
            incorrect_folders_count=$((incorrect_folders_count+1))
        fi
    done

    # Виводимо кількість файлів з неправильними правами
    if [ "$incorrect_files_count" -gt 0 ]; then
        log_message "${RED}Кількість файлів з неправильними правами доступу: $incorrect_files_count${RESET}"
    fi

    # Виводимо кількість папок з неправильними правами
    if [ "$incorrect_folders_count" -gt 0 ]; then
        log_message "${RED}Кількість папок з неправильними правами доступу: $incorrect_folders_count${RESET}"
    fi

    # Якщо не було файлів або папок з неправильними правами, вивести повідомлення
    if [ "$incorrect_files_count" -eq 0 ] && [ "$incorrect_folders_count" -eq 0 ]; then
        log_message "${GREEN}Всі файли та папки мають правильні права доступу.${RESET}"
    fi
}

# Викликаємо перевірки
get_last_error_log
check_wordpress_update
check_database_errors
check_vulnerable_plugins
check_caching
check_critical_urls
check_git_files
check_security_settings
check_permissions

# Запит на вибір дії
echo -e "${YELLOW}Обери дію:${RESET}"
echo "1. Виправити права доступу"
echo "2. Відключити плагіни та .htaccess"
echo "3. Замінити дефолтні файли WordPress"
read -p "Введіть номер вибору (1/2/3): " choice

case $choice in
    1)
        fix_permissions
        ;;
    2)
        disable_plugins_and_htaccess
        ;;
    3)
        replace_default_files
        ;;
    *)
        log_message "${RED}Невірний вибір!${RESET}"
        ;;
esac
