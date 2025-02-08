#!/bin/bash
clear

# Визначення шляху до сайту
SITE_PATH="$(pwd)"

# Кольорові змінні
RED='\033[0;31m'
ORANGE='\033[0;33m'
RESET='\033[0m'

# Функція для виводу повідомлень
log_message() {
    echo -e "$1"
}

# Функція для отримання останнього запису в error_log
get_last_error_log() {
    error_log_file="$SITE_PATH/error_log"

    if [ -f "$error_log_file" ]; then 
        last_modified=$(stat -c "%y" "$error_log_file")  
        last_log=$(tail -n 1 "$error_log_file")  
        log_message "${ORANGE}Last Modified (error_log):${RESET} $last_modified"
        log_message "${ORANGE}Error_log:${RESET} $last_log"
    else
        log_message "${RED}Файл error_log не знайдений.${RESET}"
    fi
}

# Виклик функції
get_last_error_log
