#!/bin/bash
# https://habr.com/ru/company/ruvds/blog/325522/ - Bash documentation
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# set -e - прекращает выполнение скрипта, если команда завершилась ошибкой
# set -u - прекращает выполнение скрипта, если встретилась несуществующая переменная
# set -x - выводит выполняемые команды в stdout перед выполнением (только для отладки, а то замусоривает журнал!)
# set -o pipefail - прекращает выполнение скрипта, даже если одна из частей пайпа завершилась ошибкой
set -euo pipefail
SCRIPT_FILE=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_FILE")
bash -n "$SCRIPT_FILE" || exit # check syntax this file

# colors
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

# colored messages
echoerr()  { echo -e "${Red}$@${Reset}"    1>&2; } # ошибки
echowarn() { echo -e "${Yellow}$@${Reset}" 1>&2; } # предупреждения
echohead() { echo -e "${Blue}$@${Reset}" ; } # заголовок или этап
echoinfo() { echo -e "${White}$@${Reset}" ; } # важные сообщения
echosucc() { echo -e "${Green}$@${Reset}" ; } # сообщения об успехе

#------------------------------------------------------------------
if test "$#" -ne 1; then
  echoinfo "Usage: $0 NUMBER" >&2
  echo -e "Reads last PostgreSQL log file (.csv, .csv.zst, .csv.xz, .csv.bz3) to standard output." >&2
  echo -e "If log file does not exist, no error throw, just empty output." >&2
  echo -e "\nExamples:\n $0 1    reads today log file\n $0 2    reads yesterday log file and so on" >&2
  exit 2
elif ! (echo "$1" | grep -qP '^\d+$'); then
  echoerr "Error: digits only expected in first parameter, '$1' given"
  exit 2
fi

LOG_DIR="/var/log/postgresql/16"
# sort files by name in reverse order; 'sed "$1!d"' means delete all lines, exept line $1
FILE=$(ls -1 -U $LOG_DIR | grep -P '\.csv(\.[^.]+)?$' | sort -r | sed "$1!d")
test -z "$FILE" && exit 0 # exit if files does not exist

FILE_EXT=$(echo "$FILE" | grep -oP '\.\K[^.]+$')
test "$FILE_EXT" = "zst" && (zstdcat $LOG_DIR/$FILE ; exit)
test "$FILE_EXT" = "xz"  && (xzcat   $LOG_DIR/$FILE ; exit)
test "$FILE_EXT" = "bz3" && (bz3cat  $LOG_DIR/$FILE ; exit)
test "$FILE_EXT" = "csv" && (cat     $LOG_DIR/$FILE ; exit)

echoerr "Error: file '$FILE': file extension '$FILE_EXT' does not support"
exit 1