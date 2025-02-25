#!/bin/bash

web_root="$HOME"

if [ ! -d "$web_root" ]; then
  echo -e "\033[31mКаталог $web_root не знайдено. Перевірте шлях до вашого веб-сайту.\033[0m"
  exit 1
fi

declare -a dir_paths
counter=1

check_wordpress() {
  [ -f "$1/wp-config.php" ] && dir_paths+=("$1") && echo -e "$counter.\033[92m WordPress:\033[0m \033[94m$1\033[0m" && ((counter++))
}

check_joomla() {
  [ -f "$1/administrator/manifests/files/joomla.xml" ] && dir_paths+=("$1") && echo -e "$counter. \033[92mJoomla:\033[0m \033[94m$1\033[0m" && ((counter++))
}

check_drupal() {
  [ -f "$1/sites/default/settings.php" ] && dir_paths+=("$1") && echo -e "$counter. \033[92mDrupal:\033[0m \033[94m$1\033[0m" && ((counter++))
}

check_magento() {
  [ -f "$1/composer.json" ] && [ -d "$1/vendor" ] && [ -f "$1/app/etc/env.php" ] && dir_paths+=("$1") && echo -e "$counter. \033[92mMagento:\033[0m \033[94m$1\033[0m" && ((counter++))
}

check_laravel() {
  [ -f "$1/artisan" ] && [ -f "$1/composer.json" ] && dir_paths+=("$1") && echo -e "$counter. \033[92mLaravel:\033[0m \033[94m$1\033[0m" && ((counter++))
}

check_codeigniter() {
  [ -f "$1/system/core/CodeIgniter.php" ] && dir_paths+=("$1") && echo -e "$counter. \033[92mCodeIgniter:\033[0m \033[94m$1\033[0m" && ((counter++))
}

for dir in $(find "$web_root" -maxdepth 3 -type d 2>/dev/null); do
  check_wordpress "$dir"
  check_joomla "$dir"
  check_drupal "$dir"
  check_magento "$dir"
  check_laravel "$dir"
  check_codeigniter "$dir"
done

read -p "Введіть номер каталогу: " choice

if [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#dir_paths[@]} ]]; then
    selected_dir="${dir_paths[$choice-1]}"
    selected_basename=$(basename "$selected_dir")

 
    if [ -f "$selected_dir/wp-config.php" ]; then
        echo -e "\033[92mВибрано WordPress сайт, виконую перевірку прав.\033[0m"
        cd "$selected_dir" && bash <(curl -s https://raw.githubusercontent.com/ledoAc/domain/main/wordpress.sh)
    elif [ -f "$selected_dir/administrator/manifests/files/joomla.xml" ]; then
        echo -e "\033[92mВибрано Joomla сайт, виконую перевірку.\033[0m"
        cd "$selected_dir" && bash <(curl -s https://raw.githubusercontent.com/ledoAc/domain/main/joomla.sh)
    elif [ -f "$selected_dir/artisan" ]; then
        echo -e "\033[92mВибрано Laravel сайт, виконую перевірку.\033[0m"
        cd "$selected_dir" && bash <(curl -s https://raw.githubusercontent.com/ledoAc/domain/main/laravel.sh)
    else
        echo -e "\033[31mНа жаль для вибраного каталогу ще не доступна перевірка. Вибачте за незручності.\033[0m"
    fi
else
    echo -e "\033[31mНевірний вибір, спробуйте ще раз.\033[0m"
fi
