#!/bin/bash
clear

if [ -z "$1" ]; then
    echo "Usage: $0 <Domain>"
    exit 1
fi

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


print_in_frame_records() {
    local text="$1"
    local color="\e[4;96m"
    local reset="\e[0m"

    echo -e "${color}${text}${reset}"
}

print_in_frame_blue() {
    local text="$1"
    local length=${#text}
    local border=$(printf "─%.0s" $(seq -1 $length))

    echo
    echo -e "\e[104m\e[1m+${border}+\e[0m"
    echo -e "\e[104m\e[1m| $text |"
    echo -e "\e[104m\e[1m+${border}+\e[0m"
}

print_in_frame_red() {
    local text="$1"
    local length=${#text}
    local border=$(printf "─%.0s" $(seq -1 $length))

    echo
    echo -e "\e[101m\e[1m+${border}+\e[0m"
    echo -e "\e[101m\e[1m| $text |"
    echo -e "\e[101m\e[1m+${border}+\e[0m"
}

echo -e "\e[96m###################################################################################################################################################\e[0m"

if [ "$#" -eq 2 ]; then
    domain="$1"
    param="$2"

    if [ "$param" = "-p" ]; then

        serv_a_records=$(dig +short +trace +nodnssec "$domain" A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
        web_serv=$(dig +short -x "$serv_a_records")

        if [[ "$web_serv" == *"web-hosting.com"* ]]; then
      print_in_frame "Redirect"

get_domain_without_www() {
    echo "$1" | sed 's/^www\.//'
}

location=$(wget -S --spider --max-redirect=0 -O /dev/null "$1" 2>&1 | grep "Location:" | cut -d ' ' -f2)

if [ -z "$location" ]; then
    echo "No redirection"
else

    redirect_domain=$(echo "$location" | sed 's/https\?:\/\///' | cut -d'/' -f1)

    original_domain_without_www=$(get_domain_without_www "$1")
    redirect_domain_without_www=$(get_domain_without_www "$redirect_domain")

    if [ "$original_domain_without_www" = "$redirect_domain_without_www" ]; then
        echo "No redirection"
    else
        echo -e "There is a redirect to\e[31m $location\e[0m"
    fi
fi

	print_in_frame "Number of connections to ports"
            server_record=$(dig +short -x "$serv_a_records" | cut -d'-' -f1)
            ssh_port443=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789  "wh@$server_record.web-hosting.com" "netstat -anp | grep :443 | grep ESTABLISHED | wc -l")
            ssh_port80=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789  "wh@$server_record.web-hosting.com" "netstat -anp | grep :80 | grep ESTABLISHED | wc -l")        
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

            print_in_frame "ModSec"
		modsec=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "grep $domain /usr/local/apache/logs/error_log | grep -i modsec | tail -n 1")
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
            haproxy=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "grep -qi \"$domain\" /etc/haproxy/acl_block_{base,dom,path}.lst && echo -e 'blocked'")

            if [ -n "$haproxy" ]; then
                echo "The domain $domain is $haproxy"
            else
                echo "The domain $domain is not blocked in HAProxy"
            fi

            iptables=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 "wh@$server_record.web-hosting.com" "sudo csf -g \"$domain\" | grep -qi iptablock && echo -e '\e[31mblocked in iptables\e[0m'")

            if [ -n "$iptables" ]; then
                echo "The domain $domain is $iptables"
            else
                echo "The domain $domain is not blocked in iptables"
            fi

            print_in_frame "Response time"

            response_time=$({ time curl -Ilk example.com; } 2>&1 | grep '^real\|^user\|^sys')

            echo "$response_time"

            print_in_frame "Checking all ports for domain"

            nmap_output=$(nmap --top-ports 20 "$domain")
            echo "$nmap_output" | grep -E '^[0-9]'
            echo
echo -e "\e[96m####################################################################################################################################################\e[0m"

else
while [[ -z "$server_record_new" ]]; do
                 read -p "Enter the full name of the server: " server_record_new
            done
             print_in_frame "Redirect"

get_domain_without_www() {
    echo "$1" | sed 's/^www\.//'
}

location=$(wget -S --spider --max-redirect=0 -O /dev/null "$1" 2>&1 | grep "Location:" | cut -d ' ' -f2)

if [ -z "$location" ]; then
    echo "No redirection"
else

    redirect_domain=$(echo "$location" | sed 's/https\?:\/\///' | cut -d'/' -f1)

    original_domain_without_www=$(get_domain_without_www "$1")
    redirect_domain_without_www=$(get_domain_without_www "$redirect_domain")

    if [ "$original_domain_without_www" = "$redirect_domain_without_www" ]; then
        echo "No redirection"
    else
        echo -e "There is a redirect to\e[31m $location\e[0m"
    fi
fi

print_in_frame "Number of connections to ports"
ssh_port443_new=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "netstat -anp | grep :443 | grep ESTABLISHED | wc -l")
ssh_port80_new=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "netstat -anp | grep :80 | grep ESTABLISHED | wc -l")
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

print_in_frame "ModSec"
domain="$domain"
modsec=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "grep $domain /usr/local/apache/logs/error_log | grep -i modsec | tail -n 1")
date=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new "date")

if [ -n "$modsec" ]; then
    echo "$modsec"
else
    echo "No logs"
fi
echo "----------------------------------"
echo "Server date: $date"

print_in_frame "HAProxy and CSF blocks"

haproxy=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new  "grep -qi $domain /etc/haproxy/acl_block_{base,dom,path}.lst && echo -e ''")
if [ -n "$haproxy" ]; then
    echo "The domain $domain is $haproxy"
else
    echo "The domain $domain is not blocked in HAProxy"
fi

iptables=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -q -p 12789 wh@$server_record_new  "sudo csf -g $domain | grep -qi iptablock && echo -e '\e[31mblocked in'")
if [ -n "$iptables" ]; then
    echo "The domain $domain is $iptables"
else
    echo "The domain $domain is not blocked in iptables"
fi

print_in_frame "Response time"

response_time=$({ time curl -Ilk "$domain"; } 2>&1 | grep '^real\|^user\|^sys')
echo "$response_time"
        print_in_frame "Checking all ports for domain"

        nmap_output=$(nmap --top-ports 20 $domain)
        echo "$nmap_output" | grep -E '^[0-9]'
        echo
echo -e "\e[96m####################################################################################################################################################\e[0m"
        fi
    fi
fi



if [ "$#" -eq 1 ]; then
    domain="$1"

    output=$(whois "$1" | grep -i "serverHold")

    if [ -n "$output" ]; then
        print_in_frame_red "Domain blocks"
        echo -e " $output"
    else
        print_in_frame "Domain blocks"
        echo -e "There are no serverHold restrictions for this domain "
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

     who_is=$(whois $domain | grep -E "Updated Date|Name Server|Registry Expiry Date|Registrar:")

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

    print_in_frame "A,MX,TXT,PTR records"

    print_in_frame_records "A record"

    a_records=$(dig +short +trace +nodnssec $domain A | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 2 | head -n 1)
    who_ip=$(whois "$a_records" | grep -E "OrgName" | awk '{$1=""; print $0}')

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
    echo -e "\e[96m###################################################################################################################################################\e[0m"
fi
