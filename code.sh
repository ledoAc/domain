#!/bin/bash
#autor: Ostap Beshchanyk
#version: 2.5

clear

if [ -z "$1" ]; then
    echo "Usage: $0 <Domain>"
    exit 1
fi
domain="$1"
#color of the frame is bright cyan
print_in_frame() {
    local text="$1"
    local length=${#text}
    local border=$(printf "─%.0s" $(seq -1 $length))
    local corner_border=$(printf "─%.0s" $(seq 3 $((length + 4))))

    echo
    echo -e "\e[96m\e[1m╭─${corner_border// /─}─╮\e[0m"
    echo -e "\e[96m\e[1m│  $text  │"
    echo -e "\e[96m\e[1m╰─${corner_border// /─}─╯\e[0m"
}
print_in_frame_dom() {
    local text="$1"
    local color="\e[96m"
    local reset="\e[0m"

    echo -e "${color}${text}${reset}"
}
#records frame color
print_in_frame_records() {
    local text="$1"
    local color="\e[4;96m"
    local reset="\e[0m"

    echo -e "${color}${text}${reset}"
}
#color of the frame is blue
print_in_frame_blue() {
    local text="$1"
    local length=${#text}
    local border=$(printf "─%.0s" $(seq -1 $length))

    echo
    echo -e "\e[104m\e[1m+${border}+\e[0m"
    echo -e "\e[104m\e[1m| $text |"
    echo -e "\e[104m\e[1m+${border}+\e[0m"
}
#color of the frame is red
print_in_frame_red() {
    local text="$1"
    local length=${#text}
    local border=$(printf "─%.0s" $(seq -1 $length))

    echo
    echo -e "\e[101m\e[1m+${border}+\e[0m"
    echo -e "\e[101m\e[1m| $text |"
    echo -e "\e[101m\e[1m+${border}+\e[0m"
}

#uppercase domain
echo_domain=$(echo "$domain" | tr '[:lower:]' '[:upper:]')
echo -e "\e[96m#####################################################\e[0m \e[46m\e[30m | GENERAL INFORMATION FOR $echo_domain | \e[0m \e[96m #######################################################\e[0m"
check_tld() {
    tld="$1"
    case $tld in
        de|br|it|fr|is)
            echo -e "\e[96m\e[1m Note that \e[41m.$tld\e[0m\e[96m\e[1m domains have specific requirements for nameservers.\n Specifically, before nameservers are changed, there should be a DNS zone created for \e[41m.$tld\e[0m\e[96m\e[1m domain in advance.\n This is why you will need to add domain to hosting first, and then change nameservers.\e[0m"
            ;;
    esac
}

tld=$(echo "$domain" | awk -F '.' '{print $NF}')

if [ "$#" -eq 2 ]; then

    domain="$1"

    param="$2"



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

found_cpu_mem=false

while IFS= read -r line; do
    if $found_cpu_mem; then
   echo "$line"
    else 
        if [[ $line == *"=====================| CPU & MEM |====================="* ]]; then
        echo
            print_in_frame_dom "=====================| CPU & MEM |====================="
            found_cpu_mem=true
        fi
    fi
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -p" 2>/dev/null)


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




echo -e "\e[96m####################################################################################################################################################\e[0"



        else

            while [[ -z "$server_record_new" ]]; do

                read -p "Enter the full name of the server: " server_record_new
            done

cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new"  "sudo /scripts/whoowns $domain")

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
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -d" 2>/dev/null | tr -d '\0')

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
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -m" 2>/dev/null | tr -d '\0')


echo

echo -e "\e[96m####################################################################################################################################################\e[0"



        fi
    fi
fi


if [ "$#" -eq 2 ]; then
    param="$2"
    domain="$1"
    if [ "$param" = "-scan" ]; then
        serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
        web_serv=$(dig +short -x "$serv_a_records")
print_in_frame "Scan"
        if [[ "$web_serv" == *"web-hosting.com"* ]]; then
            server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)
            cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /scripts/whoowns $domain")
            echo "Select scan type:"
            echo "1. Scan"
            echo "2. Scan with quarantine"
            read -p "Your choice (1 or 2): " CHOICE

            case $CHOICE in
                1)
                    scan_report=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /usr/local/sbin/cxs.sh --filemax 50000 -B --user $cuser --report \"/home/$cuser/scanreport-$cuser-$(date '+%b_%d_%Y_%Hh%Mm').txt\"")
                    echo "Scan in progress..."
                    echo "Scan report: tail /home/$cuser/scanreport-$cuser-$(date '+%b_%d_%Y_%Hh%Mm').txt"
                    ;;
                2)
                    scan_report=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /usr/local/sbin/cxs.sh --filemax 50000 -B --user $cuser --report \"/home/$cuser/scanreport-$cuser-quarantine-$(date '+%b_%d_%Y_%Hh%Mm').txt\" --quarantine /opt/cxs/quarantine")
                    echo "Scan with quarantine in progress..."
                    echo "Scan report: tail /home/$cuser/scanreport-$cuser-quarantine-$(date '+%b_%d_%Y_%Hh%Mm').txt"
                    ;;
                *)
                    echo "Invalid choice. Please choose 1 or 2."
                    exit 1
                    ;;
            esac

            echo
            echo -e "\e[96m####################################################################################################################################################\e[0}"

        else
            while [[ -z "$server_record_new" ]]; do
                read -p "Enter the full name of the server: " server_record_new
            done
            server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)
            cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$serv_a_records" "sudo /scripts/whoowns $domain")
            echo "Select scan type:"
            echo "1. Scan"
            echo "2. Scan with quarantine"
            read -p "Your choice (1 or 2): " CHOICE

            case $CHOICE in
                1)
                    scan_report=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$serv_a_records" "sudo /usr/local/sbin/cxs.sh --filemax 50000 -B --user $cuser --report \"/home/$cuser/scanreport-$cuser-$(date '+%b_%d_%Y_%Hh%Mm').txt\"")
                    echo "Scan in progress..."
		    echo "Scan report: tail /home/$cuser/scanreport-$cuser-$(date '+%b_%d_%Y_%Hh%Mm').txt"
                    ;;
                2)
                    scan_report=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$serv_a_records" "sudo /usr/local/sbin/cxs.sh --filemax 50000 -B --user $cuser --report \"/home/$cuser/scanreport-$cuser-quarantine-$(date '+%b_%d_%Y_%Hh%Mm').txt\" --quarantine /opt/cxs/quarantine")
                    echo "Scan with quarantine in progress..."
                    echo "Scan report: tail /home/$cuser/scanreport-$cuser-quarantine-$(date '+%b_%d_%Y_%Hh%Mm').txt"
                    ;;
                *)
                    echo "Invalid choice. Please choose 1 or 2."
                    exit 1
                    ;;
            esac
            echo -e "\e[96m####################################################################################################################################################\e[0}"
        fi
    fi
fi




if [ "$#" -eq 2 ]; then
    domain="$1"
    param="$2"

    if [ "$param" = "-header" ]; then

        serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
        web_serv=$(dig +short -x "$serv_a_records")

        if [[ "$web_serv" == *"web-hosting.com"* ]]; then
 server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)
read -p "Enter ID: " input_email
        email="$input_email"
cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com"  "sudo /scripts/whoowns $domain")

print_in_frame "Header"

linKheader=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep -irl $email /home/$cuser/mail")
header=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /usr/local/sbin/cat.sh $linKheader")
clean_header=$(echo "$header" | sed 's/^Grepping in "\/home\/eyepptup\/mail"//')

echo "$clean_header"


echo
echo -e "\e[96m####################################################################################################################################################\e[0"

        else
            while [[ -z "$server_record_new" ]]; do
                read -p "Enter the full name of the server: " server_record_new
            done
read -p "Enter ID: " input_email
email="$input_email"
cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new"  "sudo /scripts/whoowns $domain")
print_in_frame "Header"

linKheader=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep -irl $email /home/$cuser/mail")
header=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /usr/local/sbin/cat.sh $linKheader")
clean_header=$(echo "$header" | sed 's/^Grepping in "\/home\/eyepptup\/mail"//')

echo "$clean_header"
echo -e "\e[96m####################################################################################################################################################\e[0"

        fi
    fi

fi



if [ "$#" -eq 2 ]; then

    domain="$1"

    param="$2"



    if [ "$param" = "-s" ]; then



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
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -L" 2>/dev/null | tr -d '\0')

echo

echo -e "\e[96m####################################################################################################################################################\e[0"



        else

            while [[ -z "$server_record_new" ]]; do

                read -p "Enter the full name of the server: " server_record_new
            done

cuser=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new"  "sudo /scripts/whoowns $domain")

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
done < <(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/scripts/techsup/check_user_load.sh -u $cuser -L" 2>/dev/null | tr -d '\0')


echo

echo -e "\e[96m####################################################################################################################################################\e[0"



        fi
    fi
fi




show_help() {
echo
echo "-h - help information"
echo "-p - connect to the server"
echo "-i - IP information"
echo "-e - email information"
echo "-c - DOMLOGS"
echo "-s - DOMLOGS section for each domain name."
echo
print_in_frame_records  "The main page displays information about the domain:"
echo -e "- checks the domain for the serverHold block\n- WHOIS\n- Nameserver\n- Glue record\n- displays records (A, MX, TXT, CNAME, DKIM, SPF, DMARC, PTR)\n- shows who owns the IP\n- checks if the IP belongs to EasyWP\n- checks if the nameservers belong to Spaceship\n- Displays the TLD domains for which a DNS zone should be created before adding name servers."
echo
print_in_frame_records "flag -p displays:"
echo -e "\n- cPanel information\n- Number of connections to ports\n- TTFB\n- Response time\n- ModSec\n- HAProxy\n- CSF\n- SuperSonic CDN IP block\n- Ezoik\n- Redirection\n- Cron log\n- Login log\n- FTP log"
echo
print_in_frame_records "flag -i displays:"
echo -e "\n- check IP\n- modsec\n- HAProxy\n- cPHulk\n- LFD"
echo
print_in_frame_records "flag -e displays:"
echo -e "\n- Maillog\n- Exim\n- POP3"
echo
print_in_frame_records "flag -c displays:"
echo -e "\n- Show the DOMLOGS section only."
print_in_frame_records "flag -s displays:"
echo -e "\n- Show the DOMLOGS section for each domain name."
echo
}
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-help" ]]; then
    show_help
echo -e "\e[96m####################################################################################################################################################\e[0"
    exit 0
fi

if [ "$#" -eq 2 ]; then
    domain="$1"
    param="$2"

    if [ "$param" = "-i" ]; then

        serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
        web_serv=$(dig +short -x "$serv_a_records")

        if [[ "$web_serv" == *"web-hosting.com"* ]]; then
            server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)
            read -p "Enter IP: " input_ip
            checkip="$input_ip"


            print_in_frame "cPHulk"

 echo -e "\e[3;36mSearching through the cPHulk log.\e[0m"
     cphulk=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep $checkip /usr/local/cpanel/logs/cphulkd.log | tail -n 5")
            echo "$cphulk"

            print_in_frame "Check IP"

            echo -e "\e[3;36mChecking whether the IP is blocked in the firewall.\e[0m"
     check_ip=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /usr/sbin/csf -g $checkip")
            echo "$check_ip"

          print_in_frame "LFD"

            echo -e "\e[3;36mChecking LFD log.\e[0m"
     lfd=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /usr/local/sbin/cat.sh /var/log/lfd.log | grep $checkip | tail -n 10")
            echo "$lfd"

print_in_frame "Modsec"
echo -e "\e[3;36mChecking ModSecurity-related entries from the error log.\e[0m"
mod=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "grep $checkip /usr/local/apache/logs/error_log | grep -i modsec | tail -n 5")
if [ -z "$mod" ]; then
    echo "No ModSecurity-related entries found."
else
    echo "$mod"
fi

            print_in_frame "HAProxy"
            echo -e "\e[3;36mLooking for an IP in HAProxy block lists. \e[0m"
haproxy=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep $input_ip /var/log/haproxy/access.log | tail -n 5")
            echo "$haproxy"


            echo
 echo -e "\e[96m####################################################################################################################################################\e[0"

        else
            while [[ -z "$server_record_new" ]]; do
                read -p "Enter the full name of the server: " server_record_new
            done
            read -p "Enter IP: " input_ip
            checkip="$input_ip"

            print_in_frame "cPHulk"

            echo -e "\e[3;36mChecking whether the IP is blocked in the firewall.\e[0m"
 echo -e "\e[3;36mSearching through the cPHulk log.\e[0m"
     cphulk=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep $checkip /usr/local/cpanel/logs/cphulkd.log | tail -n 5")
            echo "$cphulk"

            print_in_frame "Check IP"

            echo -e "\e[3;36mChecking whether the IP is blocked in the firewall.\e[0m"
            check_ip=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /usr/sbin/csf -g $checkip")
            echo "$check_ip"

       print_in_frame "LFD"

            echo -e "\e[3;36mChecking LFD log.\e[0m"
     lfd=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /usr/local/sbin/cat.sh /var/log/lfd.log | grep $checkip | tail -n 10")
            echo "$lfd"

print_in_frame "Modsec"
echo -e "\e[3;36mChecking ModSecurity-related entries from the error log.\e[0m"
mod=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "grep $checkip /usr/local/apache/logs/error_log | grep -i modsec | tail -n 5")
if [ -z "$mod" ]; then
    echo "No ModSecurity-related entries found."
else
    echo "$mod"
fi

            print_in_frame "HAProxy"
            echo -e "\e[3;36mLooking for an IP in HAProxy block lists. \e[0m"
haproxy=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep $input_ip /var/log/haproxy/access.log | tail -n 5")
            echo "$haproxy"

            echo
echo -e "\e[96m####################################################################################################################################################\e[0"

        fi
    fi
fi





domain="$1"
tld=$(echo "$domain" | awk -F '.' '{print $NF}')
check_tld "$tld"
echo
if [ "$#" -eq 2 ]; then
    domain="$1"
    param="$2"

    if [ "$param" = "-e" ]; then

        serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
        web_serv=$(dig +short -x "$serv_a_records")

        if [[ "$web_serv" == *"web-hosting.com"* ]]; then
 server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)
read -p "Enter email address or ID: " input_email
        email="$input_email"
print_in_frame "Maillog"

echo -e "\e[3;36mProcessing logs of issues related to mail clients (eg successful email client logins, failed logins causing IPs to be blocked) and SpamAssassin.\e[0m"
email_log=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep -i $email /var/log/maillog | tail -n 5")
             echo "$email_log"
print_in_frame "Exim"
echo -e "\e[3;36mSearching through exim_mainlog .\e[0m"

exim=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep $email /var/log//exim_mainlog | tail -n 5")
echo "$exim"

print_in_frame "POP3"
echo -e "\e[3;36mSearching through exim_mainlog POP3 .\e[0m"

pop=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep -i $email  /var/log//maillog | grep pop3 | tail")
echo "$pop"

echo
echo -e "\e[96m####################################################################################################################################################\e[0"

        else
            while [[ -z "$server_record_new" ]]; do
                read -p "Enter the full name of the server: " server_record_new
            done
read -p "Enter email address or ID: " input_email
email="$input_email"
        print_in_frame "Maillog"
echo -e "\e[3;36mProcessing logs of issues related to mail clients (eg successful email client logins, failed logins causing IPs to be blocked) and SpamAssassin.\e[0m"

  email_log=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep -i $email /var/log/maillog | tail -n 5")
            echo "$email_log"
print_in_frame "Exim"
echo -e "\e[3;36mSearching through exim_mainlog .\e[0m"

exim=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep $email /var/log/exim_mainlog | tail -n 5")
echo "$exim"
print_in_frame "POP3"
echo -e "\e[3;36mSearching through exim_mainlog POP3 .\e[0m"

pop=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep -i $email  /var/log/maillog | grep pop3 | tail")

echo "$pop"

echo
echo -e "\e[96m####################################################################################################################################################\e[0"

        fi
    fi

fi




if [ "$#" -eq 2 ]; then
    domain="$1"
    param="$2"
#second parameter
    if [ "$param" = "-p" ]; then

        serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
        web_serv=$(dig +short -x "$serv_a_records")

        if [[ "$web_serv" == *"web-hosting.com"* ]]; then

	print_in_frame "Number of connections to ports and TTFB"
            server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)
            ssh_port443=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789  "wh@$server_record.web-hosting.com" "netstat -anp 2>/dev/null | grep :443 | grep ESTABLISHED | wc -l")
            ssh_port80=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789  "wh@$server_record.web-hosting.com" "netstat -anp 2>/dev/null | grep :80 | grep ESTABLISHED | wc -l")        
cloud_rel=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record.web-hosting.com "cat /etc/redhat-release | awk -F '(' '{print \$1}'")
ttfb=$(curl -o /dev/null -sw "Connect: %{time_connect} \nTTFB: %{time_starttransfer} \nTotal time: %{time_total} \n" https:/$domain/)
echo "$ttfb"
echo
echo -e "\e[3;36mIf TTFB is higher than 5 seconds – smth is going on in the web server and is better to be reported to SME.\nIf TTFB is low (less than 1 second (1000ms) can be considered as tolerable for shared hosts).\e[0m"
echo 
echo -e  "Server: $(dig +short -x "$serv_a_records") -- $cloud_rel "
            echo "Established connections to port 443: $ssh_port443"
            echo "Established connections to port 80: $ssh_port80"
		echo
echo -e "\e[3;36m1k+ connections on port 80 = possible DDoS; \e[3m5k+ connections on port 443 = possible upcoming or mitigated DDoS; \e[3;36m10k+ connections on port 443 = ongoing DDoS.\e[0m"


            print_in_frame "Response time"

            response_time=$({ time curl -Ilk example.com; } 2>&1 | grep '^real\|^user\|^sys')

            echo "$response_time"

            print_in_frame "ModSec"
		modsec=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record.web-hosting.com "grep $domain /usr/local/apache/logs/error_log | grep -i modsec | tail -n 2")
            date=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "date")

            if [ -n "$modsec" ]; then
                echo "$modsec"
            else
                echo "No logs"
            fi
            echo "----------------------------------"
            echo "Server date: $date"

            print_in_frame "HAProxy and CSF blocks"

            domain="$domain"
            unset ni nh
            haproxy=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "grep -qi \"$domain\" /etc/haproxy/acl_block_{base,dom,path}.lst && echo -e '\e[41mblocked in HAProxy\e[0m'")

            if [ -n "$haproxy" ]; then
                echo "The domain $domain is $haproxy"
            else
                echo "The domain $domain is not blocked in HAProxy"
            fi

            iptables=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo csf -g \"$domain\" | grep -qi iptablock && echo -e '\e[41mblocked in IPtables\e[0m'")

            if [ -n "$iptables" ]; then
                echo "The domain $domain is $iptables"
            else
                echo "The domain $domain is not blocked in iptables"
            fi


 print_in_frame "Logs"

print_in_frame_records "Cron"
echo -e "\e[3;36mChecking the log of recently triggered cron jobs of a cPanel account.\e[0m"
echo
cron=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep $user 2>/dev/null /var/log/cron | tail -n 5")
if [ -n "$cron" ]; then
    echo "$cron"
else
    echo "There is no cron"
fi
echo
print_in_frame_records "Login"
echo -e "\e[3;36mSearching through cPanel login log. This log shows a list of failed and deferred login attempts to cPanel or WHM.\e[0m"
echo
login=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep $user /usr/local/cpanel/logs/login_log | tail -n 5")
echo "$login"
print_in_frame_records "FTP"
echo -e "\e[3;36mSearching through the system FTP log. This log stores valuable, non-debug and non-critical messages. This log should be considered the "general system activity" log.\e[0m"
echo
login=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo /root/bin/csgrep -i $user /var/log/pure_ftpd.log | tail -n 5")
echo "$login"


echo -e "\e[96m####################################################################################################################################################\e[0m"

else
while [[ -z "$server_record_new" ]]; do
                 read -p "Enter the full name of the server: " server_record_new
            done

print_in_frame "Number of connections to ports and TTFB"
ssh_port443_new=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "netstat -anp 2>/dev/null | grep :443 | grep ESTABLISHED | wc -l")
ssh_port80_new=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "netstat -anp 2>/dev/null | grep :80 | grep ESTABLISHED | wc -l")
cloud_rel=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "cat /etc/redhat-release | awk -F '(' '{print \$1}'")
ttfb=$(curl -o /dev/null -sw "Connect: %{time_connect} \nTTFB: %{time_starttransfer} \nTotal time: %{time_total} \n" https:/$domain/)
echo "$ttfb"
echo
echo -e "\e[3;36mIf TTFB is higher than 5 seconds – smth is going on in the web server and is better to be reported to SME.\nIf TTFB is low (less than 1 second (1000ms) can be considered as tolerable for shared hosts).\e[0m"
echo
echo -e  "Server: $server_record_new -- $cloud_rel "
echo "Established connections to port 443: $ssh_port443_new"
echo "Established connections to port 80: $ssh_port80_new"
echo
echo -e "\e[3;36m1k+ connections on port 80 = possible DDoS; \e[3m5k+ connections on port 443 = possible upcoming or mitigated DDoS; \e[3;36m10k+ connections on port 443 = ongoing DDoS.\e[0m"

print_in_frame "Response time"

response_time=$({ time curl -Ilk "$domain"; } 2>&1 | grep '^real\|^user\|^sys')
echo "$response_time"

print_in_frame "ModSec"
domain="$domain"
modsec=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "grep $domain /usr/local/apache/logs/error_log | grep -i modsec | tail -n 2")
date=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "date")

if [ -n "$modsec" ]; then
    echo "$modsec"
else
    echo "No logs"
fi
echo "----------------------------------"
echo "Server date: $date"

print_in_frame "HAProxy and CSF blocks"

haproxy=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new  "grep -qi $domain /etc/haproxy/acl_block_{base,dom,path}.lst && echo -e '\e[41mblocked in HAProxy\e[0m'")
if [ -n "$haproxy" ]; then
    echo "The domain $domain is $haproxy"
else
    echo "The domain $domain is not blocked in HAProxy"
fi

iptables=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new  "sudo csf -g $domain | grep -qi iptablock && echo -e echo -e '\e[41mblocked in IPtables\e[0m'")
if [ -n "$iptables" ]; then
    echo "The domain $domain is $iptables"
else
    echo "The domain $domain is not blocked in iptables"
fi

 print_in_frame "Logs"

print_in_frame_records "Cron"
echo -e "\e[3;36mChecking the log of recently triggered cron jobs of a cPanel account.\e[0m"
echo
cron=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep $user 2>/dev/null /var/log/cron | tail -n 5")
if [ -n "$cron" ]; then
    echo "$cron"
else
    echo "There is no cron"
fi
echo
print_in_frame_records "Login"
echo -e "\e[3;36mSearching through cPanel login log. This log shows a list of failed and deferred login attempts to cPanel or WHM.\e[0m"
echo
login=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep $user /usr/local/cpanel/logs/login_log | tail -n 5")
echo "$login"
echo
print_in_frame_records "FTP"
echo -e "\e[3;36mSearching through the system FTP log. This log stores valuable, non-debug and non-critical messages. This log should be considered the "general system activity" log.\e[0m"
echo
login=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record_new" "sudo /root/bin/csgrep -i $user /var/log/pure_ftpd.log | tail -n 5")
echo "$login"
echo -e "\e[96m####################################################################################################################################################\e[0m"
        fi
    fi
fi



if [ "$#" -eq 1 ]; then
    domain="$1"

    print_in_frame "A,MX,TXT,PTR... records"

    print_in_frame_records "A record"

    a_records=$(dig +short +trace +nodnssec $domain A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
    who_ip=$(whois "$a_records" | grep -E "OrgName|netname" | awk '{$1=""; print $0}')

    if [ -n "$a_records" ]; then
        if [[ "$a_records" == *"100.100.100.6"* ]]; then
            echo -n -e "The domain is not pointed to hosting or desync.\n"
        else
            echo -n  -e "$a_records - $who_ip"
        fi
    else
        echo -e "No A record"
    fi
    echo

    easy_a=$(dig +short $domain A)

    check_easywp_ip() {
        local ip=$1
        if [[ " ${ip_addresses[@]} " =~ " $ip " ]]; then
            print_in_frame_red "The IP address $ip belongs to EasyWP"
        fi
    }

    ip_addresses=(
        "162.255.118.65"
        "162.255.118.66"
        "162.255.118.67"
        "162.255.118.68"
        "63.250.43.1"
        "63.250.43.2"
        "63.250.43.3"
        "63.250.43.4"
        "63.250.43.5"
        "63.250.43.6"
        "63.250.43.7"
        "63.250.43.8"
        "63.250.43.9"
        "63.250.43.10"
        "63.250.43.11"
        "63.250.43.12"
        "63.250.43.13"
        "63.250.43.14"
        "63.250.43.15"
        "63.250.43.16"
        "63.250.43.128"
        "63.250.43.129"
        "63.250.43.130"
        "63.250.43.131"
        "63.250.43.132"
        "63.250.43.133"
        "63.250.43.134"
        "63.250.43.135"
        "63.250.43.136"
        "63.250.43.137"
        "63.250.43.138"
        "63.250.43.139"
        "63.250.43.144"
        "63.250.43.145"
        "63.250.43.146"
        "63.250.43.147"
    )

    for ip in ${easy_a[@]}; do
        check_easywp_ip "$ip"
    done

    print_in_frame_records "MX record"

    mx_records=$(dig +short +trace +nodnssec $domain MX | grep '^MX' | sed 's/ from.*//')

    if [ -n "$mx_records" ]; then
        echo -e "$mx_records"
    else
        echo -e "No MX records"
    fi
    echo

    print_in_frame_records "TXT record"

txt_records=$(dig +short +trace +nodnssec $domain TXT | grep '^TXT' | sed 's/ from.*//')
if [ -n "$txt_records" ]; then
    echo "$txt_records"
else
    echo -e "No TXT records."
fi
echo

  print_in_frame_records "SOA record"

    soa_records=$(dig +short +trace +nodnssec $domain SOA | tail -n 1)

    if [ -n "$soa_records" ]; then
        echo "$soa_records"
    else
        echo -e "No SOA records."
    fi
    echo

    print_in_frame_records "DKIM record"

    dkim_records=$(host -t TXT default._domainkey.$domain)

    if [ -n "$dkim_records" ]; then
        echo "$dkim_records"
    else
        echo -e "No DKIM records."
    fi
    echo

    print_in_frame_records "DMARC record"

    dmarc_records=$(host -t TXT _dmarc.$domain)

    if [ -n "$dmarc_records" ]; then
        echo "$dmarc_records"
    else
        echo -e "No DMARC records."
    fi
    echo

    print_in_frame_records "CNAME record"

    cname_rec=$(dig +short +trace +nodnssec www.$domain CNAME | tail -n 1)
    echo -e "$cname_rec"
    echo

    print_in_frame_records "PTR record"

    ptr_record=$(dig +short -x $a_records)
    if [ -n "$ptr_record" ]; then
        echo "PTR record $a_records: $ptr_record "
    else
        echo "No PTR records found for IP address."
    fi
	echo

output_serverHold=$(whois "$1" | grep -i "serverHold")
output_clientHold=$(whois "$1" | grep -i "clientHold")

if [ -n "$output_serverHold" ] || [ -n "$output_clientHold" ]; then
    print_in_frame_red "Domain blocks"
    if [ -n "$output_serverHold" ]; then
        echo -e " $output_serverHold"
    fi
    if [ -n "$output_clientHold" ]; then
        echo -e " $output_clientHold"
    fi
else
    print_in_frame "Domain blocks"
    echo -e "There are no serverHold or clientHold restrictions for this domain"
fi


    ns_records=$(dig +short NS @8.8.8.8 "$domain")

    print_in_frame "Nameservers"

    if [ -z "$ns_records" ]; then
        echo -e "\nUnfortunately, there are no Nameservers records for the domain $domain. Maybe the domain doesn't point to the server.\n"
    else
        echo "$ns_records" | while read -r line; do
            if [[ "$line" == *"launch1.spaceship.net"* || "$line" == *"launch2.spaceship.net"* ]]; then
                print_in_frame_blue "---Spaceship--$line"
            else
                echo "$line"
            fi
        done
    fi

    print_in_frame "WHOIS"

     who_is=$(whois $domain | grep -E "Updated Date|Name Server|Registry Expiry Date|Registrar:|owner:|nserver:|organization:|organization-loc:")

    tld=$(echo "$domain" | awk -F '.' '{print $NF}')

    if [ "$tld" = "pk" ]; then
        echo "This TLD has no whois server, but you can access the whois database at http://www.pknic.net.pk/"
    fi


    echo -e "$who_is"

    print_in_frame "Glue records"

    if [ -z "$ns_records" ]; then
        echo -e "\nUnfortunately, there are no Glue records for the domain $domain. Maybe they haven't been created yet.\n"
    else
        while read -r ns; do
            ip=$(dig +short @8.8.8.8 $ns)
            echo -e "----- $ns ----- $ip ---- "
        done <<< "$ns_records"
    fi

    echo
    echo -e "\e[96m###################################################################################################################################################\e[0m"
fi
