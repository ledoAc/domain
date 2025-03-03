#!/bin/bash

print_in_frame_dom() {
    local text="$1"
    local color="\e[96m"
    local reset="\e[0m"

    echo -e "${color}${text}${reset}"
}


# Якщо домен не передано як параметр, запитуємо його
if [ -z "$1" ]; then
  read -p "Введіть домен: " domain
else
  domain="$1"
fi

# Перевірка, чи домен введено
if [ -z "$domain" ]; then
  echo "Домен не введено. Завершення скрипта."
  exit 1
fi

echo "Обраний домен: $domain"

# Отримуємо A записи для домену
serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)

# Перевірка на наявність A запису
if [ -z "$serv_a_records" ]; then
  echo "A запис для домену $domain не знайдено"
  exit 1
fi

# Зворотний пошук DNS для A запису
web_serv=$(dig +short -x "$serv_a_records")

# Виведення всього аутпуту
echo "Результати для домену $domain:"
echo "--------------------------------------------------"
dig +short +trace "$domain"
echo "--------------------------------------------------"
echo

# Виведення IP-адрес
echo "IP адреси для домену $domain:"
echo "$serv_a_records"
echo

# Виведення бота (якщо у зворотному записі присутні ключові слова)
echo "Перевірка на наявність ботів:"
if [[ "$web_serv" == *"bot"* || "$web_serv" == *"crawler"* || "$web_serv" == *"spider"* ]]; then
    echo "Виявлено бота: $web_serv"
else
    echo "Боти не знайдені"
fi

# Окремо виводимо інформацію про IP та агентів
echo "--------------------------------------------------"
echo "Список IP та ботів з аутпуту:"
echo "--------------------------------------------------"

# Виводимо список IP адрес
echo "IP адреси:"
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' <<< "$serv_a_records"
echo

# Виведення бота зі списку user-agent
echo "Боти (User Agents):"
grep -i 'bot\|crawler\|spider' <<< "$web_serv"
echo

# Для перевірки наявності URL-посилань або інших відповідних даних
echo "--------------------------------------------------"
echo "URL-посилання з аутпуту:"
grep -oE '\/[^\s]+' <<< "$web_serv"
echo "--------------------------------------------------"
