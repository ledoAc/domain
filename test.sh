#!/bin/bash

# 1. Отримуємо значення з wp-config.php
DB_NAME=$(grep "DB_NAME" wp-config.php | cut -d "'" -f 4)
DB_USER=$(grep "DB_USER" wp-config.php | cut -d "'" -f 4)
DB_PREFIX=$(grep "table_prefix" wp-config.php | cut -d "'" -f 2)

# 2. Отримуємо реальні значення через WP-CLI
REAL_DB_NAME=$(wp config get DB_NAME)
REAL_DB_USER=$(wp config get DB_USER)
REAL_DB_PREFIX=$(wp db query "SHOW TABLES LIKE '${DB_PREFIX}%'" --silent --skip-column-names | head -n 1)

# 3. Видаляємо суфікс з першої знайденої таблиці, щоб залишився лише префікс
REAL_DB_PREFIX=$(echo "$REAL_DB_PREFIX" | sed -E "s/(_.*)//")

# 4. Порівнюємо
echo "📌 Перевірка налаштувань бази даних:"
[[ "$DB_NAME" == "$REAL_DB_NAME" ]] && echo "✅ Назва бази даних збігається" || echo "❌ Різні назви БД: $DB_NAME ≠ $REAL_DB_NAME"
[[ "$DB_USER" == "$REAL_DB_USER" ]] && echo "✅ Користувач БД збігається" || echo "❌ Різні користувачі БД: $DB_USER ≠ $REAL_DB_USER"
[[ "$DB_PREFIX" == "$REAL_DB_PREFIX" ]] && echo "✅ Префікс таблиць збігається" || echo "❌ Різні префікси: '$DB_PREFIX' ≠ '$REAL_DB_PREFIX'"
