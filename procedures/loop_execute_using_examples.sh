#распараллеливание выполнения SQL запроса по ядрам процессора

#cpu_max=`nproc`
cpu_max=$((`nproc` / 2))
#echo "$cpu_max"

name=`basename $0 .sh`
user='user'         #modify me!
password='password' #modify me!
host='host'         #modify me!
database='database' #modify me!

#exit 0 #ok
#exit 1 #error

regexp="\buse_cpu\s*\(\s*([^,]+)\s*,\s*[0-9]+\s*,\s*[0-9]+\s*\)"

if cat "${name}.sql" | grep -q -P -e "${regexp}"; then
else
    echo "Функция use_cpu() для распараллеливания SQL запроса по ${cpu_max} ядрам процессора НЕ найдена! Будет использовано только 1 ядро.
    cpu_max=1
fi

echo "Распараллеливаем SQL запрос по ${cpu_max} ядрам процессора"

for ((cpu_num = 1; cpu_num <= cpu_max; cpu_num++))
do
    cat "${name}.sql" \
        | sed -E -e "s/${regexp}/use_cpu(\1, ${cpu_num}, ${cpu_max})/g" \
        | psql postgresql://${user}:${password}@${host}:5433/${database}?application_name=${0} \
               --echo-all --set="ON_ERROR_STOP=1" \
               --log-file=${name}_${cpu_num}.log 2> ${name}_${cpu_num}.stderr.log &
done

jobs -l

#wait
#echo "All done"
