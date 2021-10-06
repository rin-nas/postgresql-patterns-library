#распараллеливание выполнения SQL по ядрам процессора

#cpu_max=`nproc`
cpu_max=$((`nproc` / 2))
#echo "$cpu_max"

name=`basename $0 .sh`
host='host'         #modify me!
database='database' #modify me!
user='user'         #modify me!
#пароль укажите в файле ~/.pgpass, нельзя хранить в GIT этот файл с настоящими настройками подключения к БД!

#exit 0
 
for ((cpu_num = 1; cpu_num <= cpu_max; cpu_num++))
do
    cat ${name}.sql \
        | sed "s/cpu_num constant smallint default 1/cpu_num constant smallint default $cpu_num/g" \
        | sed "s/cpu_max constant smallint default 1/cpu_max constant smallint default $cpu_max/g" \
        | psql postgresql://${user}@${host}:5433/${database}?application_name=${0} \
               --echo-all --set="ON_ERROR_STOP=1" \
               --log-file=${name}_${cpu_num}.log 2> ${name}_${cpu_num}.stderr.log &
done

jobs -l

#wait #wait for all remaining workers
#echo "All done"
