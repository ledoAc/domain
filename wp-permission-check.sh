#!bin/bash
clear
# Отримуємо поточний шлях
wp_path=$(pwd)

# Колірні коди для форматування виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
ORANGE='\033[0;38;5;214m'
LIGHT_GREEN='\033[1;32m'

# Функція для логування
log_message() {
    local message="$1"
    echo -e "$message"
}

# Перевірка на наявність файлу version.php
if [ -f "$wp_path/wp-includes/version.php" ]; then
    version=$(grep "\$wp_version =" "$wp_path/wp-includes/version.php" | cut -d "'" -f 2)
    log_message "${ORANGE}Версія WordPress: $version${RESET}"
else
    log_message "${YELLOW}Файл version.php не знайдений. ${RESET}"
fi

# Функція для перевірки прав доступу
check_permissions() {
    log_message "${ORANGE}Перевірка папок та файлів з неправильними правами доступу...${RESET}"

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
        log_message "${LIGHT_GREEN}Всі файли та папки мають правильні права доступу.${RESET}"
    fi
}

remove_htaccess_files() {
  echo -e "${RED}Пошук та видалення файлів .htaccess...${RESET}"

  # Знаходимо всі .htaccess файли
  cdhtaccess=$(find . -type f -name ".htaccess")

  # Якщо файли знайдено, видаляємо їх
  if [ -n "$cdhtaccess" ]; then
    for file in $cdhtaccess; do
      rm "$file"
      echo -e "${GREEN}Файл $file видалено.${RESET}"
    done
  else
    echo -e "${RED}Файли .htaccess не знайдено.${RESET}"
  fi
}

check_database_errors() {
    log_message "${ORANGE}Перевірка помилок бази даних...${RESET}"

    # Перевіряємо базу даних на помилки за допомогою WP-CLI
    if command -v wp &> /dev/null; then
        wp db check
    else
        log_message "${RED}WP-CLI не знайдений. Перевірка бази даних неможлива.${RESET}"
    fi
}

echo -e "${ORANGE}Пошук файлів, які не належать Wordpress...${RESET}"

cdfind=$(find . -type f \
    -not -path "./wp-admin/*" \
    -not -path "./wp-includes/*" \
    -not -path "./wp-content/*" \
    -not -name "wp-*" \
    -not -name "index.php" \
    -not -name "license.txt" \
    -not -name ".htaccess" \
    -not -name ".hcflag" \
    -not -name "error_log" \
    -not -name "readme.html")

echo "$cdfind"

echo -e "${ORANGE}Пошук файлів htaccess...${RESET}"

cdhtaccess=$(find . -type f -name ".htaccess")

if [ -n "$cdhtaccess" ]; then
  echo -e "${GREEN}$cdhtaccess${RESET}"
else
  echo -e "${GREEN}Файли .htaccess не знайдено.${RESET}"
fi



# Функція для зміни пароля користувача
change_user_password() {
    log_message "${GREEN}Зміна пароля для адміністратора...${RESET}"

    # Виводимо список користувачів
    wp user list

    # Запитуємо ім'я користувача та новий пароль
    read -p "Введіть ім'я користувача для зміни пароля: " username
    read -sp "Введіть новий пароль: " new_password
    echo

    # Оновлюємо пароль
    wp user update "$username" --user_pass="$new_password"
    log_message "${ORANGE}Пароль для користувача $username оновлено.${RESET}"
}

# Функція для додавання нового адміністратора
add_new_admin() {
    log_message "${ORANGE}Додавання нового адміністратора...${RESET}"

    # Запитуємо ім'я користувача, email та пароль
    read -p "Введіть ім'я нового користувача: " username
    read -p "Введіть email нового користувача: " email
    read -sp "Введіть пароль нового користувача: " password
    echo

    # Створюємо нового користувача з правами адміністратора
    wp user create "$username" "$email" --role=administrator --user_pass="$password"
    log_message "${ORANGE}Новий адміністратор $username доданий.${RESET}"
}

# Функція для оновлення ролі користувача
update_user_role() {
    log_message "${ORANGE}Оновлення ролі користувача...${RESET}"
    # Виводимо список користувачів
    wp user list
    # Запитуємо ID користувача та нову роль
    read -p "Введіть ID користувача для оновлення ролі: " user_id
    read -p "Введіть нову роль (наприклад, subscriber, editor, administrator): " role

    # Оновлюємо роль користувача
    wp user update "$user_id" --role="$role"
    log_message "${ORANGE}Роль користувача з ID $user_id оновлено на $role.${RESET}"
}

# Функція для виправлення прав доступу
fix_permissions() {
    log_message "${ORANGE}Виправлення прав доступу...${RESET}"

    # Встановлюємо правильні права для файлів
    find "$wp_path" -type f ! -perm 644 -exec chmod 644 {} \;

    # Встановлюємо правильні права для папок
    find "$wp_path" -type d ! -perm 755 -exec chmod 755 {} \;

    # Перевіряємо, чи змінилися права доступу
    log_message "${ORANGE}Права доступу виправлені.${RESET}"
}

# Функція для отримання останнього рядка error_log і дати його модифікації
get_last_error_log() {
    error_log_file="./error_log"
    if [ -f "$error_log_file" ]; then 
        last_modified=$(stat -c "%y" "$error_log_file")  # Отримуємо дату останньої модифікації
        last_log=$(tail -n 1 "$error_log_file")  # Отримуємо останній рядок
        log_message "${ORANGE}Last Modified (error_log):${RESET} $last_modified"
        log_message "${ORANGE}Error_log:${RESET} $last_log"
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

    log_message "${ORANGE}Завантаження та заміна дефолтних файлів WordPress версії $wp_version...${RESET}"

    # Завантажуємо та встановлюємо версію WordPress
    wp core download --force --version="$wp_version" --path="$wp_path"

    log_message "${ORANGE}Дефолтні файли успішно замінено на версію $wp_version.${RESET}"
}

# Функція для відключення плагінів та .htaccess
disable_plugins_and_htaccess() {
    log_message "${ORANGE}Відключення плагінів та .htaccess...${RESET}"

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
check_database_errors

# Запит на вибір дії
echo -e "${YELLOW}Обери дію:${RESET}"
echo "1. Змінити пароль адміністратора"
echo "2. Додати нового адміністратора"
echo "3. Оновити роль користувача"
echo "4. Виправити права доступу"
echo "5. Відключити плагіни та .htaccess"
echo "6. Замінити дефолтні файли WordPress"
echo "7. Видалити .htaccess файли"
echo "8. Вихід"
read -p "Введіть номер вибору: " choice

case $choice in
    1)
        change_user_password
        ;;
    2)
        add_new_admin
        ;;
    3)
        update_user_role
        ;;
    4)
        fix_permissions
        ;;
    5)
        disable_plugins_and_htaccess
        ;;
    6)
        replace_default_files
        ;;
    7) 
        remove_htaccess_files
        ;;
    8)
       exit 0
       ;;
    *)
        log_message "${RED}Невірний вибір!${RESET}"
        ;;
esac
