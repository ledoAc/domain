#!/bin/bash
clear

wp_path=$(pwd)
 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
ORANGE='\033[0;38;5;214m'
LIGHT_GREEN='\033[1;32m'
AIOWPM_URL="https://github.com/d0n601/All-In-One-WP-Migration-With-Import/archive/master.zip"

echo -e "${LIGHT_GREEN}#################### WordPress troubleshooter ####################${RESET}"
function run_wpcli {
  php -d memory_limit=512M /usr/local/sbin/wp "$@"
}

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
user_list() {
    echo -e "${ORANGE}Список користувачів WordPress:${RESET}"
    wp user list
}
url_site(){
home_url=$(wp option get home)
siteurl=$(wp option get siteurl)
echo -e "${ORANGE}Сайти в базі даних _options :${RESET}"

echo "Home URL: $home_url"
echo "Site URL: $siteurl"

}


remove_htaccess_files() {
  echo -e "${RED}Пошук та видалення файлів .htaccess...${RESET}"

  htaccess_files=$(find . -type f -name ".htaccess")

  if [ -n "$htaccess_files" ]; then
    for file in $htaccess_files; do
      rm "$file"
      echo -e "${GREEN}Файл $file видалено.${RESET}"
    done
  else
    echo -e "${RED}Файли .htaccess не знайдено.${RESET}"
  fi
}

check_database_errors() {
    log_message "${ORANGE}Перевірка помилок бази даних...${RESET}"

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
  echo -e "${LIGHT_GREEN}Файли .htaccess не знайдено.${RESET}"
fi

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
        echo -e "${LIGHT_GREEN}Дамп БД збережено у $DB_BACKUP ${RESET}"+-
    else
        echo "Помилка експорту бази даних!"
        exit 1
    fi

    echo -e "${YELLOW}Архівування файлів WordPress...${RESET}"

    TOTAL_FILES=$(find "$SITE_PATH" -type f | wc -l)
    PROCESSED_FILES=0

    zip -r -v "$ZIP_BACKUP" "$SITE_PATH" | awk -v total="$TOTAL_FILES" '
        BEGIN { 
            printf "Прогрес: ["
        }
        {
            if ($0 ~ /adding:/) {
                processed++
                percent = int((processed / total) * 100)
                printf "\rПрогрес: [%-50s] %d%%", substr("##################################################", 1, percent / 2), percent
                fflush(stdout)
            }
        }
        END {
            printf "]\n"
        }
    '

    if [ $? -eq 0 ]; then
        echo -e "${ORANGE} Бекап файлів збережено у $ZIP_BACKUP ${RESET}"
    else
        echo "Помилка архівування файлів!"
        exit 1
    fi

    echo -e "${LIGHT_GREEN}Процес бекапу завершено!${RESET}"
}



 restore_wp_backup() {

  [[ ! -f "${PWD}/wp-config.php" ]] && { echo "WordPress незнайдено"; return 1; }
  BACKUPS=($(find "${PWD}" -type f -name "*.wpress"))
  [[ -z "${BACKUPS[*]}" ]] && { echo "Бекапів немає"; return 1; }
  php -v | grep -qP 'PHP (7\.4|8\.\d)\.' || { echo "Please use PHP 7.4 or 8.X"; return 1; }

  [[ "${#BACKUPS[@]}" -gt 1 ]] && { echo "${BACKUPS[@]}" | nl | column -t; read -rp "Виберіть бекап: " CHOICE; BACKUP_PATH="${BACKUPS[$((CHOICE-1))]}"; } || BACKUP_PATH="${BACKUPS[0]}"
  echo -e "${ORANGE}Виберіть бекап: ${BACKUP_PATH} ${RESET}"

  read -rp -e "${ORANGE}Відновити? [y/n]: ${RESET}" CONFIRM
  [[ ! "${CONFIRM}" =~ ^[yY](es)?$ ]] && { echo "Скасовано"; return 1; }
  AI1WM_PATH="${PWD}/wp-content/ai1wm-backups"
  mkdir -p "${AI1WM_PATH}"
  mv "${BACKUP_PATH}" "${AI1WM_PATH}"

  run_wpcli plugin delete all-in-one-wp-migration 2>/dev/null
  wget -qP "${PWD}/wp-content/plugins" "${AIOWPM_URL}" || { echo "Не вдалося завантажити плагін"; return 1; }
  unzip -q -o "${PWD}/wp-content/plugins/master.zip" -d "${PWD}/wp-content/plugins" || { echo "Не вдалося розпакувати плагін"; return 1; }
  mv "${PWD}/wp-content/plugins/All-In-One-WP-Migration-With-Import-master" "${PWD}/wp-content/plugins/all-in-one-wp-migration"
  rm -f "${PWD}/wp-content/plugins/master.zip"
  
  run_wpcli plugin activate all-in-one-wp-migration
  run_wpcli ai1wm restore "$(basename "${BACKUP_PATH}")"
  
  run_wpcli plugin update all-in-one-wp-migration
  echo -e 'apache_modules:\n  - mod_rewrite' > "${HOME}/.wp-cli/config.yml"
  run_wpcli rewrite flush --hard
}

plugin_deactivate(){

plugins=$(wp plugin list --format=csv --fields=name | tail -n +2)

if [ -z "$plugins" ]; then
    echo "На сайті немає встановлених плагінів."
    exit 1
fi

i=1
declare -A plugin_map
echo "Оберіть плагін для деактивації:"
IFS=$'\n'
for plugin in $plugins; do
    plugin_map[$i]="$plugin"
    echo "$i. $plugin"
    ((i++))
done

read -p "Введіть номер плагіна: " plugin_number

plugin_name="${plugin_map[$plugin_number]}"

if [ -n "$plugin_name" ]; then
    wp plugin deactivate "$plugin_name"
    echo "Плагін '$plugin_name' був деактивований."
else
    echo "Невірний номер плагіна."
fi
}

theme_activation(){

themes=$(wp theme list --status=inactive --format=csv --fields=name | tail -n +2)

if [ -z "$themes" ]; then
    echo "Немає доступних тем для активації."
    exit 1
fi

i=1
declare -A theme_map
echo "Оберіть тему для активації:"
IFS=$'\n'
for theme in $themes; do
    theme_map[$i]="$theme"
    echo "$i. $theme"
    ((i++))
done

read -p "Введіть номер теми: " theme_number

theme_name="${theme_map[$theme_number]}"

if [ -n "$theme_name" ]; then
    wp theme activate "$theme_name"
    echo "Тема '$theme_name' була активована."
else
    echo "Невірний номер теми."
fi

}

replace_url(){

read -p -e "${LIGHT_GREEN}Домен який треба замінити: ${RESET}" search
read -p -e "${LIGHT_GREEN}Домен на який замінити: ${RESET}" replace

wp search-replace "$search" "$replace" --all-tables

echo "Заміна '$search' на '$replace' завершена!"

}

error_config(){

echo "hello"

}

get_last_error_log
check_permissions
check_database_errors
user_list
url_site
error_config


echo -e "${ORANGE}Обери дію:${RESET}"
echo "1. Змінити пароль адміністратора"
echo "2. Додати нового адміністратора"
echo "3. Оновити роль користувача"
echo "4. Виправити права доступу"
echo "5. Відключити плагіни та .htaccess"
echo "6. Замінити дефолтні файли WordPress"
echo "7. Видалити .htaccess файли"
echo "8. Створити .htaccess файл"
echo "9. Створити бекап"
echo "10. Відновити бекап .wpess"
echo "11. Відключити потрібний плагін"
echo "12. Змінити тему сайту"
echo "13. Замінити лінки в базі даних"
echo "14. Вихід"
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
        restore_wp_backup
        ;;
    11) 
        plugin_deactivate
        ;;
    12)
        theme_activation
        ;;
    13)
        replace_url
        ;;
     14)
        exit 0
        ;;
    *)
        log_message "${RED}Невірний вибір!${RESET}"
        ;;
esac
