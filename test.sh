#!/bin/bash
clear
# Визначення шляху до сайту
SITE_PATH="$(pwd)"
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

get_last_error_log
