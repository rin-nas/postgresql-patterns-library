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
 
# передаём в application_name основной IP текущего сервера, т.к. запрос может проходить через прокси
# https://elephas.io/how-to-set-application_name-in-psql-command-line-utility/
application_name="$(basename "$SCRIPT_FILE") $(hostname -I | cut -f1 -d' ')"
export PGAPPNAME="$application_name"
 
echo "Press CTRL+C to stop"
 
step=1
 
for i in  {1..10000}
do
    if test $step = 1; then
        echo "Ping $i. Waiting for connection to start..."
    elif test $step = 2; then
        echo "Ping $i. Waiting for disconnection to continue..."
    elif test $step = 3; then
        echo "Ping $i. Waiting for connection to finish..."
    fi
 
    psql -U postgres -q -X -c "\conninfo" -f connection_ping.sql -c "call connection_ping(1, 0)" -h $host -p $port
    status=$?
 
    if test $step = 1 && test $status = 0; then
        echowarn "Connected"
        step=2
    elif test $step = 2 && test $status != 0; then
        echowarn "Disconnected"
        time_start=$(date +%s.%3N)
        step=3
    elif test $step = 3 && test $status = 0; then
        time_end=$(date +%s.%3N)
        echowarn "Connected"
        step=4
        break
    fi
 
    sleep 0.1
done
 
if test $step = 4; then
    elapsed=$(echo "$time_end - $time_start" | bc | sed "s/^\./0./")
    echosucc "Disconnection duration: ${elapsed}s"
    exit 0
else
    echoerr "Error occured"
    exit 1
fi
