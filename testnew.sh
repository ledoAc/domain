#!/bin/bash

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

# Виведення IP-адрес і ботів
echo "IP адреси та боти з аутпуту:"

# Тут буде обробка кожного рядка
dig +short +trace "$domain" | grep -oP '\d{1,3}(\.\d{1,3}){3}\s+\|\s+\S+\s+\|\s+\S+\s+\|\s+.*' | while read -r line; do
    # Виводимо інформацію про IP адреси і відповідних ботів
    ip=$(echo "$line" | awk '{print $1}')
    country=$(echo "$line" | awk '{print $2}')
    org=$(echo "$line" | awk '{print $3, $4}')
    rdns=$(echo "$line" | awk '{print $5, $6}')
    agent=$(echo "$line" | awk '{for (i=7; i<=NF; i++) printf $i" "; print ""}')
    
    # Виведення знайдених даних
    echo "$ip | $country | $org | $rdns | $agent"
done

echo "--------------------------------------------------"
