#!/bin/bash
#https://habr.com/ru/company/ruvds/blog/325522/ - Bash documentation
 
#https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#set -euo pipefail #commented!
 
SCRIPT_FILE=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_FILE")
 
# Check syntax this file
bash -n "${SCRIPT_FILE}" || exit
 
# Colors
Red='\e[1;31m'
Green='\e[0;32m'
Yellow='\e[38;5;220m'
Blue='\e[38;5;39m'
Orange='\e[38;5;214m'
Magenta='\e[0;35m'
Cyan='\e[0;36m'
Gray='\e[0;37m'
White='\e[1;37m'
Reset='\e[0m'
 
# Colored messages
echoerr()  { echo -e "${Red}$@${Reset}"    1>&2; }
echowarn() { echo -e "${Yellow}$@${Reset}" 1>&2; }
echoinfo() { echo -e "${White}$@${Reset}" ; }
echosucc() { echo -e "${Green}$@${Reset}" ; }
 
echoinfo "PostgreSQL connection lost duration test"
 
if [ ! -n "${1-}" ]
then
    echoerr "Host is not defined as first parameter"
    echo "Usage: $SCRIPT_FILE <host> <port>"
    exit 2
fi
 
if [ ! -n "${2-}" ]
then
    echoerr "Port is not defined as second parameter"
    echo "Usage: $SCRIPT_FILE <host> <port>"
    exit 2
fi
 
host=$1
port=$2
 
cd $SCRIPT_DIR;
