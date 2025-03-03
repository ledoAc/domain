#!/bin/bash

domain="$1"

# Check if domain is provided
if [ -z "$domain" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

# Fetch the A record
serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)

# Check if the A record is empty
if [ -z "$serv_a_records" ]; then
  echo "No A record found for $domain"
  exit 1
fi

# Resolve reverse DNS for the A record
web_serv=$(dig +short -x "$serv_a_records")

# Check if the reverse DNS matches expected pattern
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
    echo "No matching web hosting service found for $domain"
fi
