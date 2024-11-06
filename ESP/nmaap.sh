#!/bin/bash

# Descripción: Script que lista los puertos rápidamente y posteriormente los escanea a un nivel más complejo.
# Fecha comienzo: 18 Octubre del 2024
# Fecha de fin: 24 Octubre del 2024
# Hecho por: Aarón Esteban Macías
# Versión: 1.0
# Basado en: https://github.com/Hackavis/nmapA/blob/main/nmapA.sh

# Gama de colores
purpura="\033[0;35m"
verde="\033[0;32m"
rojo="\033[0;31m"
fincolor="\033[0m"
amarillo="\033[0;33m"

    echo "-------------------------------------------------------------------------------------"
    echo "███╗   ██╗███╗   ███╗ █████╗  █████╗ ██████╗ "
    echo "████╗  ██║████╗ ████║██╔══██╗██╔══██╗██╔══██╗"
    echo "██╔██╗ ██║██╔████╔██║███████║███████║██████╔╝"
    echo "██║ ╚████║██║ ╚═╝ ██║██║  ██║██║  ██║██║"
    echo "╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝"
    echo "--------------------------------------------------------------------------------------"


# Verificar si se ejecuta con permisos de superusuario
if [ "$EUID" -ne 0 ]; then 
    echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
    echo -e "${rojo}[X] Ejecuta ${0} con sudo o como root.${fincolor}"
    echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
    exit 1
fi

# Verifica si está instalado nmap; si no está instalado, pregunta al usuario si desea instalarlo
if [[ -f /usr/bin/nmap || -d /usr/share/nmap ]]; then
    echo -e "${verde}-------------------------------------------------------------------------------------${fincolor}"
    echo -e "${verde}[✓] Nmap esta instalado en su sistema${fincolor}"
    echo -e "${verde}-------------------------------------------------------------------------------------${fincolor}"
else
    # Si nmap no está instalado, pregunta si desea instalarlo
    echo -e "${amarillo}-------------------------------------------------------------------------------------${fincolor}"
    echo -e "${amarillo}[!] Nmap no está instalado.${fincolor} ${purpura}¿Quieres instalarlo? (s/n)${fincolor}"
    echo -e "${amarillo}-------------------------------------------------------------------------------------${fincolor}"
    read opcion

    if [[ $opcion == "s" ]]; then
        # Detectar el sistema de paquetes y proceder con la instalación
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y nmap
        elif command -v yum &> /dev/null; then
            sudo yum install -y nmap
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y nmap
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu nmap
        else
            echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
            echo -e "${rojo}[X] No se pudo determinar el gestor de paquetes para instalar nmap.${fincolor}"
            echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
            exit 1
        fi
    elif [[ $opcion == "n" ]]; then
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
        echo -e "${rojo}[X] Instalación de Nmap cancelada.${fincolor}"
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
        exit 1 
    else
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
        echo -e "${rojo}[X] Opción no válida.${fincolor}${purpura}Por favor, elige 's' o 'n'.${fincolor}"
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
        exit 1
    fi
fi
 
if [[ $# -eq 1 ]]; then
    if [[ "$1" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then 
        echo -e "${purpura}-------------------------------------------------------------------------------------${fincolor}"
        echo -e "${purpura}[*] Reconocimiento inicial de puertos.${fincolor}"
        echo -e "${purpura}-------------------------------------------------------------------------------------${fincolor}"
        ip=$1
        nmap -p- -sS --min-rate 5000 --open -Pn -v -n $ip -oG ports.tmp
        echo -e "${verde}-------------------------------------------------------------------------------------${fincolor}"
        echo -e "${verde}[✓] Escaneo correctamente terminado.${fincolor}"
        echo -e "${verde}-------------------------------------------------------------------------------------${fincolor}"
    else
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
        echo -e "${rojo}[X] Porfavor, introduce una IPv4 correcta.${fincolor}"
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
        exit 1
    fi
else
echo -e "${amarillo}-------------------------------------------------------------------------------------${fincolor}"
echo -e "${amarillo}[!] No has introducido ninguna IPv4, porfavor vuelva a intentarlo.${fincolor}"
echo -e "${amarillo}-------------------------------------------------------------------------------------${fincolor}"
exit 1
fi
ports="$(cat ports.tmp | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
if [[ $ports = "" ]]; then
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
		echo -e "${rojo}[X] No se ha detectado ningún puerto abierto.${fincolor}"
        echo -e "${rojo}-------------------------------------------------------------------------------------${fincolor}"
		rm ports.tmp
		exit 1
else
    echo -e "${purpura}-------------------------------------------------------------------------------------${fincolor}"
    echo -e "${purpura}[*] Escaneo avanzado de servicios${fincolor}" 
    echo -e "${purpura}-------------------------------------------------------------------------------------${fincolor}"
    nmap -sCV -p$ports $ip -oN InfoPuertos
    sed -i '1,3d' InfoPuertos
    echo -e "Dirección IP: $ip" >> InfoPuertos
    echo -e "Puertos abiertos: $ports\n" >> InfoPuertos
    rm ports.tmp
    echo -e "${verde}-------------------------------------------------------------------------------------${fincolor}"
    echo -e "${verde}[✓] Escaneo completado, se ha generado el fichero InfoPuertos.${fincolor}" 
    echo -e "${verde}-------------------------------------------------------------------------------------${fincolor}"
    echo $ip | xclip -sel clip
fi
