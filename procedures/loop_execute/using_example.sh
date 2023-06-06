#распараллеливание выполнения SQL запроса по ядрам процессора
#для миграций длительностью < 5 минут этот скрипт не нужен, можно подождать

#core_max=`nproc`
#core_max=$((`nproc` / 2))
core_max=8
#echo "$core_max"

name=`basename $0 .sh`
host='host'         #modify me!
port=5433           #modify me!
database='database' #modify me!
user='user'         #modify me!
#пароль укажите в файле ~/.pgpass

#exit 0 #ok
#exit 1 #error

regexp="\buse_parallel\s*\(\s*([^,]+)\s*,\s*[0-9]+\s*,\s*[0-9]+\s*\)"

if cat "${name}.sql" | grep -q -P -e "${regexp}"; then
    echo "В SQL запросе есть вызов функции use_parallel()."
    echo "Распараллеливаем SQL запрос по ${core_max} ядрам процессора"
else
    echo "В SQL запросе нет вызова функции use_parallel()."
    echo "Поэтому распараллеливания выполнения по ${core_max} ядрам процессора не будет!"
    echo "Будет использовано только 1 ядро."
    core_max=1
fi

for ((core_num = 1; core_num <= core_max; core_num++))
do
    cat "${name}.sql" \
        | sed -E -e "s/${regexp}/use_parallel(\1, ${core_num}, ${core_max})/g" \
        | psql postgresql://${user}@${host}:${port}/${database}?application_name=${0} \
               --echo-all \
               --set="ON_ERROR_STOP=1" \
               --log-file=${name}_${core_num}.log 2> ${name}_${core_num}.stderr.log &
done

jobs -l

#wait
#echo "All done"
