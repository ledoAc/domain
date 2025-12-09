#!/bin/bash

SITE_PATH="$1"   # шлях до WP сайту
DB_USER="mysql_user"
DB_PASS="mysql_pass"
DB_HOST="localhost"

echo "[INFO] Searching for correct database for site: $SITE_PATH"

for DB in $(mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -e "SHOW DATABASES;" -s --skip-column-names); do
    # перевірка таблиці wp_options
    TABLE=$(mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB" -e "SHOW TABLES LIKE 'wp_options';" -s --skip-column-names)
    if [[ "$TABLE" == "wp_options" ]]; then
        SITEURL=$(mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB" -e "SELECT option_value FROM wp_options WHERE option_name='siteurl';" -s --skip-column-names)
        if [[ -n "$SITEURL" ]]; then
            echo "[OK] Database found: $DB"
            echo "Site URL: $SITEURL"
            break
        fi
    fi
done
