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

# Функція для виправлення прав доступу
fix_permissions() {
    log_message "${GREEN}Виправлення прав доступу...${RESET}"

    # Встановлюємо правильні права для файлів
    find "$wp_path" -type f ! -perm 644 -exec chmod 644 {} \;

    # Встановлюємо правильні права для папок
    find "$wp_path" -type d ! -perm 755 -exec chmod 755 {} \;

    # Перевіряємо, чи змінилися права доступу
    log_message "${GREEN}Права доступу виправлені.${RESET}"
}

# Функція для отримання останнього рядка error_log і дати його модифікації
get_last_error_log() {
    error_log_file="./error_log"
    if [ -f "$error_log_file" ]; then 
        last_modified=$(stat -c "%y" "$error_log_file")  # Отримуємо дату останньої модифікації
        last_log=$(tail -n 1 "$error_log_file")  # Отримуємо останній рядок
        log_message "${GREEN}Last Modified:${RESET} $last_modified"
        log_message "${GREEN}Останній рядок з error_log:${RESET} $last_log"
    else
        log_message "${RED}Файл error_log не знайдений.${RESET}"
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

# Викликаємо перевірки
get_last_error_log
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
