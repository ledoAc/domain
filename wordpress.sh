#!/bin/bash
clear

wp_path=$(pwd)


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    if [[ -z "$wp_path" || ! -d "$wp_path" ]]; then
        log_message "${RED}Помилка: wp_path не задано або не існує!${RESET}"
        return 1
    fi

    log_message "${ORANGE}Перевірка папок та файлів з неправильними правами доступу...${RESET}"

    EXPECTED_FILE_PERMS="644"
    EXPECTED_DIR_PERMS="755"

    while IFS= read -r -d '' file; do
        perms=$(stat -c "%a" "$file")
        if [[ "$perms" != "$EXPECTED_FILE_PERMS" ]]; then
            log_message "${RED}Файл з неправильними правами: $file (поточні: $perms, повинні бути: $EXPECTED_FILE_PERMS)${RESET}"
            chmod "$EXPECTED_FILE_PERMS" "$file"
        fi
    done < <(find "$wp_path" -mindepth 1 -type f -print0) # -mindepth 1 виключає саму public_html

    while IFS= read -r -d '' dir; do
        perms=$(stat -c "%a" "$dir")
        if [[ "$perms" != "$EXPECTED_DIR_PERMS" ]]; then
            log_message "${RED}Папка з неправильними правами: $dir (поточні: $perms, повинні бути: $EXPECTED_DIR_PERMS)${RESET}"
            chmod "$EXPECTED_DIR_PERMS" "$dir"
        fi
    done < <(find "$wp_path" -mindepth 1 -type d -print0) 

    log_message "${LIGHT_GREEN}Перевірка завершена.${RESET}"
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
    chmod 0644 "$htaccess_path"
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
        chmod 0644 "$DB_BACKUP"
        echo -e "${LIGHT_GREEN}Дамп БД збережено у $DB_BACKUP ${RESET}"
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
        chmod 0644 "$ZIP_BACKUP"  
        echo -e "${ORANGE}Бекап файлів збережено у $ZIP_BACKUP${RESET}"
    else
        echo "Помилка архівування файлів!"
        exit 1
    fi

    echo -e "${LIGHT_GREEN}Процес бекапу завершено!${RESET}"
}



 restore_wp_backup() {
readonly VERSION='20230406'

AIOWPM_URL="https://github.com/d0n601/All-In-One-WP-Migration-With-Import/archive/master.zip"

function run_wpcli {
  php -d memory_limit=512M /usr/local/sbin/wp "$@"
}

[[ ! -f "${PWD}/wp-config.php" ]] && { echo "No wordpress installation found in ${PWD}"; exit 1; }
BACKUPS=($(find "${PWD}" -type f -name "*.wpress"))
[[ -z "${BACKUPS[*]}" ]] && { echo "No .wpress backups found within ${PWD}"; exit 1; }
php -v | grep -qE 'PHP (7\.4|8\.[01])\.' || { echo "Please set PHP to 7.4 or 8.X"; exit 1; }

if [[ "${#BACKUPS[@]}" -gt 1 ]]; then
  NUM=1
  for i in "${BACKUPS[@]}"; do
    echo "${NUM}. $i"
    NUM=$((NUM+1))
  done | column -t

  read -rp "Choose the number: " BACKUP_CHOICE
  [[ ! "${BACKUP_CHOICE}" =~ ^[1-9]{1}[0-9]*$ ]] && { echo "Invalid choice"; exit 1; }
  ARRAY_MAPPER=$((BACKUP_CHOICE-1))
  [[ -z "${BACKUPS[${ARRAY_MAPPER}]}" ]] && { echo "Invalid choice"; exit 1; }
  BACKUP_PATH="${BACKUPS[${ARRAY_MAPPER}]}"

else
  BACKUP_PATH="${BACKUPS}"
fi

echo "Selected backup: ${BACKUP_PATH}"

read -rp "Do you want to proceed? [y/n]: " CHOICE
[[ ! "${CHOICE}" =~ ^[yY](es)?$ ]] && { echo "Ok, next time"; exit 1; }

BACKUP="$(awk -F/ '{print $NF}' <<<"${BACKUP_PATH}")"
DIRNAME="$(dirname "${BACKUP_PATH}")"
AI1WM_PATH="${PWD}/wp-content/ai1wm-backups"

if [[ "${DIRNAME}" != "${AI1WM_PATH}" ]]; then
  mkdir -p "${AI1WM_PATH}"
  mv "${BACKUP_PATH}" "${AI1WM_PATH}"
fi

if [[ -d "${PWD}/wp-content/plugins/all-in-one-wp-migration" ]]; then
  echo "Removing original all-in-one-wp-migration plugin"
  run_wpcli plugin delete all-in-one-wp-migration
fi

echo "Downloading forked all-in-one-wp-migration plugin"
wget -qP "${PWD}/wp-content/plugins" "${AIOWPM_URL}" || { echo "Failed to download ${AIOWPM_URL}"; exit 1; }

echo "Installing forked all-in-one-wp-migration plugin"
unzip -q "${PWD}/wp-content/plugins/master.zip" -d "${PWD}/wp-content/plugins" || { echo "Failed to extract ${PWD}/wp-content/plugins/master.zip"; exit 1; }
mv "${PWD}/wp-content/plugins/All-In-One-WP-Migration-With-Import-master" "${PWD}/wp-content/plugins/all-in-one-wp-migration"
rm -f "${PWD}/wp-content/plugins/master.zip"

echo "Activating forked all-in-one-wp-migration plugin"
mkdir -p "${PWD}/wp-content/ai1wm-backups"
run_wpcli plugin activate all-in-one-wp-migration

echo "Attempting to restore backup ${BACKUP_PATH}"
run_wpcli ai1wm restore "${BACKUP}"

echo "Updating all-in-one-wp-migration plugin"
run_wpcli plugin update all-in-one-wp-migration

echo "Configuring .htaccess"
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
  read -p "Домен який треба замінити: " search
  read -p "Домен на який замінити: " replace

  wp search-replace "$search" "$replace" --all-tables

  echo "Заміна '$search' на '$replace' завершена!"
}


error_config(){

echo -e "${ORANGE}Перевірка wp-config.php на налаштування...${RESET}"

wp_config_file="wp-config.php"

if [ ! -f "$wp_config_file" ]; then
    echo "Файл wp-config.php не знайдено!"
    exit 1
fi

declare -A settings
settings=(
["DISABLE_WP_CRON"]="Відключення WP Cron (автоматичне виконання задач у WordPress)"
["WP_MEMORY_LIMIT"]="Зміна ліміту пам'яті для WordPress"
["WP_DEBUG"]="Включення режиму налагодження"
["WP_DEBUG_LOG"]="Логування помилок у файл wp-content/debug.log"
["DISALLOW_FILE_EDIT"]="Відключення редактора файлів тем і плагінів через адмінку"
["AUTOMATIC_UPDATER_DISABLED"]="Вимкнення автоматичних оновлень"
["EMPTY_TRASH_DAYS"]="Відключення автоматичного очищення кошика"
["WP_POST_REVISIONS"]="Вимкнення збереження версій публікацій"
["REST_API_ENABLED"]="Вимкнення REST API для підвищення безпеки"
["WP_SITEURL"]="URL сайту (Site URL)"
["WP_HOME"]="URL домашньої сторінки"
["WP_CACHE"]="Увімкнення кешування"
["WP_ALLOW_REPAIR"]="Дозволяє ремонтувати базу даних через URL"
["WP_DEBUG_DISPLAY"]="Виведення помилок на екран"
["FORCE_SSL_ADMIN"]="Примусовий SSL для адмінки"
["DISALLOW_UNFILTERED_HTML"]="Заборона вставляти небезпечний HTML"
["WPLANG"]="Мова WordPress"
["WP_DEFAULT_THEME"]="Тема за замовчуванням"
["COOKIE_DOMAIN"]="Домен для cookie"
["COOKIEPATH"]="Шлях до cookie"
["WP_CONTENT_DIR"]="Шлях до каталогу контенту"
["WP_CONTENT_URL"]="URL каталогу контенту"
["WP_PLUGIN_DIR"]="Шлях до каталогу плагінів"
["WP_PLUGIN_URL"]="URL каталогу плагінів"
["WP_TEMP_DIR"]="Шлях до тимчасового каталогу"
["WP_MEMORY_LIMIT"]="Ліміт пам'яті для PHP"
["FORCE_SSL_LOGIN"]="Примусовий SSL для входу"
["DISALLOW_FILE_MODS"]="Запобігання змінам файлів через адмінку"
["WP_LOCAL_DEV"]="Режим для локального розвитку"
["WP_TIMEZONE_STRING"]="Тимчасова зона"
["DB_NAME"]="Назва бази даних"
["DB_USER"]="Ім’я користувача для бази даних"
["DB_PASSWORD"]="Пароль користувача для бази даних"
["DB_HOST"]="Хост для бази даних"
["DB_CHARSET"]="Набір символів для бази даних"
["DB_COLLATE"]="Коллетація бази даних"
["WP_AUTO_UPDATE_CORE"]="Автоматичні оновлення основних файлів"
["WP_BLOG_ID"]="ID блогу"
["WP_CONFIG_FILE"]="Шлях до файлу wp-config.php"
["WP_ALLOW_MULTISITE"]="Включення багатосайтовості"
["MULTISITE"]="Активування багатосайтовості"
["SUBDOMAIN_INSTALL"]="Встановлення піддоменів для мережі"
["DOMAIN_CURRENT_SITE"]="Поточний домен сайту"
["PATH_CURRENT_SITE"]="Шлях поточного сайту"
["SITE_ID_CURRENT_SITE"]="ID поточного сайту"
["WP_HTTP_BLOCK_EXTERNAL"]="Блокує зовнішні HTTP-запити"
["WP_HTTP_PROXY_HOST"]="Проксі-сервер для HTTP-запитів"
["WP_HTTP_PROXY_PORT"]="Порт для проксі"
["DISALLOW_FILE_MODS"]="Відключення можливості модифікації плагінів та тем через адмінку"

)

exclude_settings=("ABSPATH" "NONCE_SALT" "LOGGED_IN_SALT" "SECURE_AUTH_SALT" "AUTH_SALT" "NONCE_KEY" "LOGGED_IN_KEY" "SECURE_AUTH_KEY" "AUTH_KEY" "DB_COLLATE" "DB_CHARSET" "DB_HOST" "DB_PASSWORD" "DB_USER" "DB_NAME")

function check_wp_config_setting {
    setting_name=$1
    description=$2

    setting_value=$(grep -oP "define\(\s*'$setting_name',\s*'(.*?)'\);" "$wp_config_file" | sed -E "s/define\(\s*'$setting_name',\s*'(.*?)'\);/\1/")
    
    if [ -z "$setting_value" ]; then
        setting_value=$(grep -oP "define\(\s*'$setting_name',\s*(true|false)\s*\);" "$wp_config_file" | sed -E "s/define\(\s*'$setting_name',\s*(true|false)\s*\);/\1/")
    fi

    if [[ " ${exclude_settings[@]} " =~ " $setting_name " ]]; then
        return 0
    fi

    if [ ! -z "$setting_value" ]; then
        echo -e "${YELLOW}Налаштування:${RESET} $setting_name"
        echo -e "${YELLOW}Значення:${RESET} $setting_value"
        echo -e "${YELLOW}Опис:${RESET} $description"
        echo ""
    fi
}



for setting in "${!settings[@]}"; do
    check_wp_config_setting "$setting" "${settings[$setting]}"
done



}

get_last_error_log

check_database_errors
user_list
url_site
error_config

while true; do
echo -e "${ORANGE}Обери дію:${RESET}"
echo "1. Змінити пароль адміністратора"
echo "2. Додати нового адміністратора"
echo "3. Оновити роль користувача"
echo "4. Перевірити права доступу"
echo "5. Виправити права доступу"
echo "6. Відключити плагіни та .htaccess"
echo "7. Замінити дефолтні файли WordPress"
echo "8. Видалити .htaccess файли"
echo "9. Створити .htaccess файл"
echo "10. Створити бекап"
echo "11. Відновити бекап .wpess"
echo "12. Відключити потрібний плагін"
echo "13. Змінити тему сайту"
echo "14. Замінити лінки в базі даних"
echo "15. Вихід"
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
    4) check_permissions
       ;;
    5)
        fix_permissions
        ;;
    6)
        disable_plugins_and_htaccess
        ;;
    7)
        replace_default_files
        ;;
    8) 
        remove_htaccess_files
        ;;
    9)
       create_htaccess
       ;;
    10) 
        backup_wordpress
        ;;
    11) 
        restore_wp_backup
        ;;
    12)
        plugin_deactivate
        ;;
    13)
        theme_activation
        ;;
    14)
        replace_url
        ;;
     15)
        exit 0
        ;;
    *)
        log_message "${RED}Невірний вибір!${RESET}"
        ;;
esac
done
