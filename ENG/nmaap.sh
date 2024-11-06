#!/bin/bash

# Description: Script that quickly lists ports and then scans them at a more complex level.
# Start date: October 18, 2024
# End date: October 24, 2024
# Created by: Aarón Esteban Macías
# Version: 1.0
# Based on: https://github.com/Hackavis/nmapA/blob/main/nmapA.sh

# Color palette
purple="\033[0;35m"
green="\033[0;32m"
red="\033[0;31m"
resetcolor="\033[0m"
yellow="\033[0;33m"

    echo "-------------------------------------------------------------------------------------"
    echo "███╗   ██╗███╗   ███╗ █████╗  █████╗ ██████╗ "
    echo "████╗  ██║████╗ ████║██╔══██╗██╔══██╗██╔══██╗"
    echo "██╔██╗ ██║██╔████╔██║███████║███████║██████╔╝"
    echo "██║ ╚████║██║ ╚═╝ ██║██║  ██║██║  ██║██║"
    echo "╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝"
    echo "--------------------------------------------------------------------------------------"

if [ "$EUID" -ne 0 ]; then 
    echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
    echo -e "${red}[X] Run ${0} with sudo or as root.${resetcolor}"
    echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
    exit 1
fi

# Check if Nmap is installed; if not, ask the user if they want to install it
if [[ -f /usr/bin/nmap || -d /usr/share/nmap ]]; then
    echo -e "${green}-------------------------------------------------------------------------------------${resetcolor}"
    echo -e "${green}[✓] Nmap is installed on your system.${resetcolor}"
    echo -e "${green}-------------------------------------------------------------------------------------${resetcolor}"
else
    # If Nmap is not installed, ask if they want to install it
    echo -e "${yellow}-------------------------------------------------------------------------------------${resetcolor}"
    echo -e "${yellow}[!] Nmap is not installed.${resetcolor} ${purple}Do you want to install it? (y/n)${resetcolor}"
    echo -e "${yellow}-------------------------------------------------------------------------------------${resetcolor}"
    read option

    if [[ $option == "y" ]]; then
        # Detect the package manager and proceed with the installation
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y nmap
        elif command -v yum &> /dev/null; then
            sudo yum install -y nmap
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y nmap
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu nmap
        else
            echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
            echo -e "${red}[X] Could not determine the package manager to install Nmap.${resetcolor}"
            echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
            exit 1
        fi
    elif [[ $option == "n" ]]; then
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
        echo -e "${red}[X] Nmap installation canceled.${resetcolor}"
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
        exit 1 
    else
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
        echo -e "${red}[X] Invalid option.${resetcolor}${purple}Please choose 'y' or 'n'.${resetcolor}"
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
        exit 1
    fi
fi
 
if [[ $# -eq 1 ]]; then
    if [[ "$1" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then 
        echo -e "${purple}-------------------------------------------------------------------------------------${resetcolor}"
        echo -e "${purple}[*] Initial port scan.${resetcolor}"
        echo -e "${purple}-------------------------------------------------------------------------------------${resetcolor}"
        ip=$1
        nmap -p- -sS --min-rate 5000 --open -Pn -v -n $ip -oG ports.tmp
        echo -e "${green}-------------------------------------------------------------------------------------${resetcolor}"
        echo -e "${green}[✓] Scan successfully completed.${resetcolor}"
        echo -e "${green}-------------------------------------------------------------------------------------${resetcolor}"
    else
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
        echo -e "${red}[X] Please enter a valid IPv4 address.${resetcolor}"
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
        exit 1
    fi
else
echo -e "${yellow}-------------------------------------------------------------------------------------${resetcolor}"
echo -e "${yellow}[!] No IPv4 address provided, please try again.${resetcolor}"
echo -e "${yellow}-------------------------------------------------------------------------------------${resetcolor}"
exit 1
fi
ports="$(cat ports.tmp | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
if [[ $ports = "" ]]; then
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
        echo -e "${red}[X] No open ports detected.${resetcolor}"
        echo -e "${red}-------------------------------------------------------------------------------------${resetcolor}"
		rm ports.tmp
		exit 1
else
    echo -e "${purple}-------------------------------------------------------------------------------------${resetcolor}"
    echo -e "${purple}[*] Advanced service scan${resetcolor}" 
    echo -e "${purple}-------------------------------------------------------------------------------------${resetcolor}"
    nmap -sCV -p$ports $ip -oN PortInfo
    sed -i '1,3d' PortInfo
    echo -e "IP Address: $ip" >> PortInfo
    echo -e "Open ports: $ports\n" >> PortInfo
    rm ports.tmp
    echo -e "${green}-------------------------------------------------------------------------------------${resetcolor}"
    echo -e "${green}[✓] Scan completed, the PortInfo file has been generated.${resetcolor}" 
    echo -e "${green}-------------------------------------------------------------------------------------${resetcolor}"
    echo $ip | xclip -sel clip
fi
