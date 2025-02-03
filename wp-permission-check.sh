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

# Функція для перевірки CMS
detect_cms() {
    log_message "${GREEN}Перевірка встановленої CMS або скрипту...${RESET}"

    if [ -f "wp-includes/version.php" ]; then
        log_message "${BLUE}Виявлено WordPress${RESET}"
        check_wp_version
        check_permissions
        check_log_file "wp-includes/version.php"
        get_last_error_log
        ask_action
    elif [ -f "app/Mage.php" ]; then
        log_message "${BLUE}Виявлено Magento${RESET}"
        check_permissions
        check_log_file "app/Mage.php"
        get_last_error_log
    elif [ -f "includes/defines.php" ] && [ -f "libraries/cms/version/version.php" ]; then
        log_message "${BLUE}Виявлено Joomla${RESET}"
        check_permissions
        check_log_file "includes/defines.php"
        get_last_error_log
    elif [ -f "config/settings.inc.php" ]; then
        log_message "${BLUE}Виявлено PrestaShop${RESET}"
        check_permissions
        check_log_file "config/settings.inc.php"
        get_last_error_log
    elif [ -f "sites/default/settings.php" ]; then
        log_message "${BLUE}Виявлено Drupal${RESET}"
        check_permissions
        check_log_file "sites/default/settings.php"
        get_last_error_log
    elif [ -f "data/settings/config.php" ]; then
        log_message "${BLUE}Виявлено OpenCart${RESET}"
        check_permissions
        check_log_file "data/settings/config.php"
        get_last_error_log
    elif [ -f "index.php" ] && grep -q "Yii::createWebApplication" index.php; then
        log_message "${BLUE}Виявлено Yii Framework${RESET}"
        check_permissions
        check_log_file "index.php"
        get_last_error_log
    elif [ -f "thinkphp.php" ]; then
        log_message "${BLUE}Виявлено ThinkPHP${RESET}"
        check_permissions
        check_log_file "thinkphp.php"
        get_last_error_log
    elif [ -f "symfony" ] || [ -d "vendor/symfony" ]; then
        log_message "${BLUE}Виявлено Symfony${RESET}"
        check_permissions
        check_log_file "symfony"
        get_last_error_log
    else
        log_message "${RED}CMS або скрипт не визначено${RESET}"
    fi
}

# Перевірка на наявність файлу version.php
check_wp_version() {
    if [ -f "$wp_path/wp-includes/version.php" ]; then
        version=$(grep "\$wp_version =" "$wp_path/wp-includes/version.php" | cut -d "'" -f 2)
        log_message "${BLUE}Версія WordPress: $version${RESET}"
    else
        log_message "${YELLOW}Файл version.php не знайдений.${RESET}"
    fi
}

# Перевірка на наявність файлів з неправильними правами доступу
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

# Перевірка та виведення останнього рядка з лог-файлів
check_log_file() {
    local file="$1"
    log_file="$wp_path/$file"
    
    if [ -f "$log_file" ]; then
        last_modified=$(stat -c "%y" "$log_file")
        last_log=$(tail -n 1 "$log_file")
        log_message "${GREEN}Останній рядок з $file:${RESET} $last_log"
        log_message "${GREEN}Дата останньої модифікації: $last_modified${RESET}"
    else
        log_message "${RED}Файл $file не знайдений.${RESET}"
    fi
}

# Функція для отримання останнього рядка error_log
get_last_error_log() {
    error_log_file="./error_log"
    if [ -f "$error_log_file" ]; then 
        last_modified=$(stat -c "%y" "$error_log_file")
        last_log=$(tail -n 1 "$error_log_file")
        log_message "${GREEN}Last Modified:${RESET} $last_modified"
        log_message "${GREEN}Останній рядок з error_log:${RESET} $last_log"
    else
        log_message "${RED}Файл error_log не знайдений.${RESET}"
    fi
}

# Функція для перевірки файлів, які відрізняються від дефолтних
check_modified_files() {
    log_message "${GREEN}Перевірка файлів, відмінних від дефолтних...${RESET}"
    modified_files=$(wp core verify-checksums --format=json 2>/dev/null | jq -r '.checksums | to_entries[] | select(.value != null) | .key')

    if [ -n "$modified_files" ]; then
        log_message "${RED}Знайдено змінені або додані файли:${RESET}"
        echo "$modified_files"
    else
        log_message "${GREEN}Всі файли відповідають дефолтним.${RESET}"
    fi
}

# Функція для завантаження та заміни дефолтних файлів WordPress
replace_default_files() {
    echo "Введіть версію WordPress, яку потрібно завантажити (наприклад, 6.4.3):"
    read wp_version

    if [ -z "$wp_version" ]; then
        wp_version="6.4.3"  # Значення за замовчуванням
    fi

    log_message "${GREEN}Завантаження та заміна дефолтних файлів WordPress версії $wp_version...${RESET}"

    # Завантажуємо та встановлюємо версію WordPress
    wp core download --force --version="$wp_version" --path="$wp_path"

    log_message "${GREEN}Дефолтні файли успішно замінено на версію $wp_version.${RESET}"
}

# Функція для відключення плагінів та .htaccess
disable_plugins_and_htaccess() {
    log_message "${GREEN}Відключення плагінів та .htaccess...${RESET}"

    # Відключення плагінів (змінюємо права доступу до папки плагінів)
    if [ -d "$wp_path/wp-content/plugins" ]; then
        mv "$wp_path/wp-content/plugins" "$wp_path/wp-content/plugins-disabled"
        log_message "${GREEN}Папка плагінів переміщена та відключена.${RESET}"
    else
        log_message "${RED}Папка плагінів не знайдена.${RESET}"
    fi

    # Відключення .htaccess (переміщуємо його)
    if [ -f "$wp_path/.htaccess" ]; then
        mv "$wp_path/.htaccess" "$wp_path/.htaccess-disabled"
        log_message "${GREEN}.htaccess переміщено та відключено.${RESET}"
    else
        log_message "${RED}Файл .htaccess не знайдений.${RESET}"
    fi
}

# Запит на вибір дії
ask_action() {
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
}

# Викликаємо перевірку CMS
detect_cms
