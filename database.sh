#!/bin/bash

echo "Пошук баз даних WordPress на сервері..."
echo "========================================"

# Запит пароля MySQL
read -sp "Введіть пароль MySQL root: " MYSQL_PWD
echo ""

# Шукаємо бази з таблицями, схожими на WordPress
mysql -u root -p"$MYSQL_PWD" -e "
SET @min_wp_tables = 5;

SELECT 
    t.table_schema as 'База даних',
    COUNT(t.table_name) as 'Знайдено таблиць WordPress',
    GROUP_CONCAT(DISTINCT t.table_name ORDER BY t.table_name SEPARATOR ', ') as 'Таблиці'
FROM information_schema.tables t
WHERE t.table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
  AND (
    -- Типові таблиці WordPress
    t.table_name IN ('commentmeta', 'comments', 'links', 'options', 'postmeta', 'posts', 
                     'term_relationships', 'term_taxonomy', 'termmeta', 'terms', 'usermeta', 'users')
    OR
    -- Таблиці з префіксами WordPress
    t.table_name REGEXP '^wp[0-9]*_'
    OR 
    t.table_name REGEXP '^wptest_'
    OR
    t.table_name REGEXP '^wordpress_'
    OR
    -- Таблиці з закінченням як у WordPress
    t.table_name LIKE '%postmeta%'
    OR
    t.table_name LIKE '%usermeta%'
    OR
    t.table_name LIKE '%termmeta%'
  )
GROUP BY t.table_schema
HAVING COUNT(t.table_name) >= @min_wp_tables
ORDER BY COUNT(t.table_name) DESC;
"

# Перевірка наявності опцій сайту в знайдених базах
echo ""
echo "Перевірка опцій сайту в знайдених базах..."
echo "============================================"

mysql -u root -p"$MYSQL_PWD" -e "
SELECT DISTINCT table_schema 
FROM information_schema.tables 
WHERE table_name LIKE '%options%'
  AND table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
" | tail -n +2 | while read db; do
    echo "--- База: $db ---"
    mysql -u root -p"$MYSQL_PWD" -D "$db" -e "
    SELECT option_name, LEFT(option_value, 50) as option_value_preview 
    FROM ${db}.$(echo "SHOW TABLES LIKE '%options%'" | mysql -u root -p"$MYSQL_PWD" -N "$db") 
    WHERE option_name IN ('siteurl', 'home', 'blogname', 'admin_email')
    LIMIT 5;
    " 2>/dev/null || echo "Не вдалося перевірити"
done
