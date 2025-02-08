#!/bin/bash

# Функція для отримання поточної версії WordPress
get_current_version() {
    # Читання поточної версії з файлу wp-includes/version.php
    CURRENT_VERSION=$(grep '\$wp_version =' "$SITE_PATH/wp-includes/version.php" | cut -d "'" -f 2)
    echo "$CURRENT_VERSION"
}

# Визначаємо поточну папку (де запущено скрипт)
SITE_PATH="$(pwd)"

# Перевіряємо, чи існує папка wp-includes, щоб упевнитись, що це WordPress
if [ ! -d "$SITE_PATH/wp-includes" ]; then
    echo "❌ Помилка: Це не виглядає як папка WordPress!"
    exit 1
fi

# Отримуємо поточну версію
CURRENT_VERSION=$(get_current_version)

# Запитуємо користувача, яку версію встановити
echo "Поточна версія WordPress: $CURRENT_VERSION"
read -p "Введіть версію, яку хочете встановити (наприклад, 6.3.2): " VERSION

# Якщо версія не введена, то використовуємо поточну
if [ -z "$VERSION" ]; then
    VERSION=$CURRENT_VERSION
    echo "❗ Не вказано нову версію. Оновлення буде виконано до поточної версії: $CURRENT_VERSION"
fi

# Створюємо папку для бекапу (з міткою часу)
BACKUP_DIR="$SITE_PATH/wp-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Робимо бекап wp-config.php і wp-content
cp -r "$SITE_PATH/wp-config.php" "$BACKUP_DIR/" 2>/dev/null
cp -r "$SITE_PATH/wp-content" "$BACKUP_DIR/"

echo "✅ Бекап збережено в $BACKUP_DIR"

# Завантажуємо та розпаковуємо потрібну версію WordPress
wget https://wordpress.org/wordpress-$VERSION.tar.gz
tar -xzf wordpress-$VERSION.tar.gz

# Оновлюємо файли WordPress, виключаючи wp-config.php і wp-content
rsync -av wordpress/ "$SITE_PATH/" --exclude=wp-config.php --exclude=wp-content

# Очищуємо тимчасові файли
rm -rf wordpress wordpress-$VERSION.tar.gz

echo "✅ WordPress $VERSION оновлено в $SITE_PATH!"
