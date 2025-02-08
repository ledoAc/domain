#!bin/bash
clear
wp_path=$(pwd)
 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
ORANGE='\033[0;38;5;214m'
LIGHT_GREEN='\033[1;32m'

log_message() {
    local message="$1"
    echo -e "$message"
}

if [ -f "$wp_path/wp-includes/version.php" ]; then
    version=$(grep "\$wp_version =" "$wp_path/wp-includes/version.php" | cut -d "'" -f 2)
    log_message "${ORANGE}Версія WordPress: $version${RESET}"
else
    log_message "${YELLOW}Файл version.php не знайдений. ${RESET}"
fi
echo
check_permissions() {
    log_message "${ORANGE}Перевірка папок та файлів з неправильними правами доступу...${RESET}"

    
    incorrect_files_count=0
    incorrect_folders_count=0

    find "$wp_path" -type f | while read file; do
        perms=$(stat -c "%a" "$file")
        expected_perms="644"
        if [ "$perms" != "$expected_perms" ]; then
            log_message "${RED}Файл з неправильними правами доступу: $file (поточні: $perms, повинні бути: $expected_perms)${RESET}"
            incorrect_files_count=$((incorrect_files_count+1))
        fi
    done


    find "$wp_path" -type d | while read dir; do
        perms=$(stat -c "%a" "$dir")
        expected_perms="755"
        if [ "$perms" != "$expected_perms" ]; then
            log_message "${RED}Папка з неправильними правами доступу: $dir (поточні: $perms, повинні бути: $expected_perms)${RESET}"
            incorrect_folders_count=$((incorrect_folders_count+1))
        fi
    done

    
    if [ "$incorrect_files_count" -gt 0 ]; then
        log_message "${RED}Кількість файлів з неправильними правами доступу: $incorrect_files_count${RESET}"
    fi

    if [ "$incorrect_folders_count" -gt 0 ]; then
        log_message "${RED}Кількість папок з неправильними правами доступу: $incorrect_folders_count${RESET}"
    fi

    if [ "$incorrect_files_count" -eq 0 ] && [ "$incorrect_folders_count" -eq 0 ]; then
        log_message "${LIGHT_GREEN}Всі файли та папки мають правильні права доступу.${RESET}"
    fi
}
echo
remove_htaccess_files() {
  echo -e "${RED}Пошук та видалення файлів .htaccess...${RESET}"

  cdhtaccess=$(find . -type f -name ".htaccess")

  if [ -n "$cdhtaccess" ]; then
    for file in $cdhtaccess; do
      rm "$file"
      echo -e "${GREEN}Файл $file видалено.${RESET}"
    done
  else
    echo -e "${RED}Файли .htaccess не знайдено.${RESET}"
  fi
}
echo
check_database_errors() {
    log_message "${ORANGE}Перевірка помилок бази даних...${RESET}"

    if command -v wp &> /dev/null; then
        wp db check
    else
        log_message "${RED}WP-CLI не знайдений. Перевірка бази даних неможлива.${RESET}"
    fi
}
echo
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
echo
echo -e "${ORANGE}Пошук файлів htaccess...${RESET}"

cdhtaccess=$(find . -type f -name ".htaccess")

if [ -n "$cdhtaccess" ]; then
  echo -e "${GREEN}$cdhtaccess${RESET}"
else
  echo -e "${LIGHT_GREEN}Файли .htaccess не знайдено.${RESET}"
fi
echo
userlist = $(wp user list)
echo "$userlist"
echo
create_htaccess() {
  htaccess_path="./.htaccess"
  
  if [[ -f "$htaccess_path" ]]; then
    echo -e "${LIGHT_GREEN}Файл .htaccess вже існує.${RESET}"
  else
    cat > "$htaccess_path" <<EOL
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>

# END WordPress
EOL
    echo -e "${LIGHT_GREEN}Файл .htaccess успішно створено.${RESET}"
  fi
}


change_user_password() {
    log_message "${GREEN}Зміна пароля для адміністратора...${RESET}"

    wp user list

    read -p "Введіть ім'я користувача для зміни пароля: " username
    read -sp "Введіть новий пароль: " new_password
    echo

    wp user update "$username" --user_pass="$new_password"
    log_message "${ORANGE}Пароль для користувача $username оновлено.${RESET}"
}


add_new_admin() {
    log_message "${ORANGE}Додавання нового адміністратора...${RESET}"

    read -p "Введіть ім'я нового користувача: " username
    read -p "Введіть email нового користувача: " email
    read -sp "Введіть пароль нового користувача: " password
    echo

    wp user create "$username" "$email" --role=administrator --user_pass="$password"
    log_message "${ORANGE}Новий адміністратор $username доданий.${RESET}"
}

update_user_role() {
    log_message "${ORANGE}Оновлення ролі користувача...${RESET}"
    wp user list
    read -p "Введіть ID користувача для оновлення ролі: " user_id
    read -p "Введіть нову роль (наприклад, subscriber, editor, administrator): " role

 
    wp user update "$user_id" --role="$role"
    log_message "${ORANGE}Роль користувача з ID $user_id оновлено на $role.${RESET}"
}


fix_permissions() {
    log_message "${ORANGE}Виправлення прав доступу...${RESET}"

    find "$wp_path" -type f ! -perm 644 -exec chmod 644 {} \;

      find "$wp_path" -type d ! -perm 755 -exec chmod 755 {} \;

    log_message "${ORANGE}Права доступу виправлені.${RESET}"
}

get_last_error_log() {
    error_log_file="./error_log"
    if [ -f "$error_log_file" ]; then 
        last_modified=$(stat -c "%y" "$error_log_file")  
        last_log=$(tail -n 1 "$error_log_file")  
        log_message "${ORANGE}Last Modified (error_log):${RESET} $last_modified"
        log_message "${ORANGE}Error_log:${RESET} $last_log"
    else
        log_message "${RED}Файл error_log не знайдений.${RESET}"
    fi
}

replace_default_files() {
    echo "Введіть версію WordPress, яку потрібно завантажити (наприклад, 6.4.3):"
    read wp_version

    if [ -z "$wp_version" ]; then
        wp_version="6.4.3" 
    fi

    log_message "${ORANGE}Завантаження та заміна дефолтних файлів WordPress версії $wp_version...${RESET}"

    wp core download --force --version="$wp_version" --path="$wp_path"

    log_message "${ORANGE}Дефолтні файли успішно замінено на версію $wp_version.${RESET}"
}


disable_plugins_and_htaccess() {
    log_message "${ORANGE}Відключення плагінів та .htaccess...${RESET}"

    if [ -d "$wp_path/wp-content/plugins" ]; then
        mv "$wp_path/wp-content/plugins" "$wp_path/wp-content/plugins-disabled"
        log_message "${GREEN}Папка плагінів переміщена та відключена.${RESET}"
    else
        log_message "${RED}Папка плагінів не знайдена.${RESET}"
    fi


    if [ -f "$wp_path/.htaccess" ]; then
        mv "$wp_path/.htaccess" "$wp_path/.htaccess-disabled"
        log_message "${GREEN}.htaccess переміщено та відключено.${RESET}"
    else
        log_message "${RED}Файл .htaccess не знайдений.${RESET}"
    fi
}

backup_wordpress() {
    SITE_PATH="$wp_path"  
    BACKUP_PATH="$SITE_PATH/backups"   
    DATE=$(date +"%Y-%m-%d_%H-%M-%S")
    DB_BACKUP="$BACKUP_PATH/db_backup_$DATE.sql"
    ZIP_BACKUP="$BACKUP_PATH/wp_backup_$DATE.zip"

    mkdir -p "$BACKUP_PATH"

    echo "Експорт бази даних..."
    cd "$SITE_PATH"
    wp db export "$DB_BACKUP"

    if [ $? -eq 0 ]; then
        echo "Дамп БД збережено у $DB_BACKUP"
    else
        echo "Помилка експорту бази даних!"
        exit 1
    fi

    echo "Архівування файлів WordPress..."
    zip -r "$ZIP_BACKUP" "$SITE_PATH"

    if [ $? -eq 0 ]; then
        echo "Бекап файлів збережено у $ZIP_BACKUP"
    else
        echo "Помилка архівування файлів!"
        exit 1
    fi

    echo "Процес бекапу завершено!"
}



get_last_error_log
check_permissions
check_database_errors


echo -e "${YELLOW}Обери дію:${RESET}"
echo "1. Змінити пароль адміністратора"
echo "2. Додати нового адміністратора"
echo "3. Оновити роль користувача"
echo "4. Виправити права доступу"
echo "5. Відключити плагіни та .htaccess"
echo "6. Замінити дефолтні файли WordPress"
echo "7. Видалити .htaccess файли"
echo "8. Створити .htaccess файл"
echo "9. Створити бекап"
echo "10. Вихід"
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
       create_htaccess
       ;;
    9) 
        backup_wordpress
        ;;
     10) 
        exit 0
        ;;
    *)
        log_message "${RED}Невірний вибір!${RESET}"
        ;;
esac
