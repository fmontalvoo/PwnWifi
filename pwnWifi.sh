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

trap ctrl_c INT

function ctrl_c(){
    echo "Saliendo..."
}

function helpPanel(){
    echo -e "\n${greenColor}[i] Uso: ./pwnWifi.sh${endColor}"
    echo -e "\n\n\t${grayColor}[-a]${endColor}${yellowColor} Modo de ataque:${endColor}"
    echo -e "\t\t\t\t${redColor}Handshake${endColor}"
    echo -e "\t\t\t\t${redColor}PKMID${endColor}"
    echo -e "\n\t${grayColor}[-n]${endColor}${yellowColor} Nombre de la tarjeta de red${endColor}\n"
    exit 0
}

function startAttack(){
    echo $1 $2
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
        startAttack $attack_mode $network_card
    fi

else
    echo -e "${redColor}[!] No eres root${endColor}"

fi