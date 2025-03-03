#!/bin/bash

  if [ "$param" = "-c" ]; then



        serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)

        web_serv=$(dig +short -x "$serv_a_records")



        if [[ "$web_serv" == *"web-hosting.com"* ]]; then

 server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)

cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com"  "sudo /scripts/whoowns $domain")
found_domlogs=false

while IFS= read -r line; do
    if $found_domlogs; then
        echo "$line"
    else
        if [[ $line == *"=====================| DOMLOGS |====================="* ]]; then
            echo
print_in_frame_dom "=====================| DOMLOGS |====================="
            found_domlogs=true
        fi
    fi
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -d" 2>/dev/null | tr -d '\0')
echo

while IFS= read -r line; do
    echo "$line"  
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -p" 2>/dev/null | tr -d '\0')


found_mysql=false

while IFS= read -r line; do
    if $found_mysql; then
        echo "$line"
    else
        if [[ $line == *"=====================| MYSQL |====================="* ]]; then
            echo
print_in_frame_dom "=====================| MYSQL |====================="
            found_mysql=true
        fi
    fi
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -m" 2>/dev/null | tr -d '\0')


echo

