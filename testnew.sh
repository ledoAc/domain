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

# Виведення тільки IP
echo "IP адреси для домену $domain:"
echo "$serv_a_records"

# Фільтруємо і виводимо ботів, якщо в зворотному записі DNS є ключові слова, що вказують на бота
echo "Перевірка на наявність ботів (наприклад, якщо в зворотному записі DNS міститься 'bot' або схожі фрази):"
if [[ "$web_serv" == *"bot"* || "$web_serv" == *"crawler"* || "$web_serv" == *"spider"* ]]; then
    echo "Виявлено бота: $web_serv"
else
    echo "Боти не знайдені"
fi

# Перевірка, чи зворотний DNS містить потрібну інформацію
if [[ "$web_serv" == *"web-hosting.com"* ]]; then
    server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)

    cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com"  "sudo /scripts/whoowns $domain")
    
    found_domlogs=false
    while IFS= read -r line; do
        if [[ $found_domlogs == true ]]; then
            echo "$line"
        else
            if [[ $line == *"=====================| DOMLOGS |====================="* ]]; then
                echo
                print_in_frame_dom "=====================| DOMLOGS |====================="
                found_domlogs=true
            fi
        fi
    done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -d" 2>/dev/null)

    echo

    while IFS= read -r line; do
        echo "$line"
    done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -p" 2>/dev/null)

    found_mysql=false
    while IFS= read -r line; do
        if [[ $found_mysql == true ]]; then
            echo "$line"
        else
            if [[ $line == *"=====================| MYSQL |====================="* ]]; then
                echo
                print_in_frame_dom "=====================| MYSQL |====================="
                found_mysql=true
            fi
        fi
    done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -m" 2>/dev/null)

    echo
else
    echo "Не знайдено відповідного хостинга для домену $domain"
fi
