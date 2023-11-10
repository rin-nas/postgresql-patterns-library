# Эксперимент по созданию и восстановлению дампов БД в разных форматах с разным сжатием

## Размер БД

```
petrov@my-server:/mnt/data/tmp/dump$ psql -U postgres --host=127.0.0.1
psql (12.12 (Ubuntu 12.12-0ubuntu0.20.04.1), server 12.11 (Debian 12.11-1.pgdg110+1))
Type "help" for help.

postgres=# \l+
                                                                          List of databases
      Name         |  Owner  | Encoding |   Collate   |    Ctype    |    Access privileges    |  Size   | Tablespace |                Description                 
-------------------+---------+----------+-------------+-------------+-------------------------+---------+------------+----------------------------
 my_database       | mike    | UTF8     | ru_RU.UTF-8 | ru_RU.UTF-8 | =Tc/mike               +| 2102 MB | pg_default | 
```

## pg_dump

**--format=plain**

```
petrov@my-server:/mnt/data/tmp/dump$ time (pg_dump -U postgres --host=127.0.0.1 --format=plain --clean --if-exists --dbname=my_database | pzstd -5 > my_database.sql.zst)
real   0m14.378s
user   0m20.637s
sys    0m3.525s

petrov@my-server:/mnt/data/tmp/dump$ time (pg_dump -U postgres --host=127.0.0.1 --format=plain --clean --if-exists --dbname=my_database | pigz -5 > my_database.sql.gz)
real   0m29.185s
user   1m9.290s
sys    0m5.663s
```
Многопоточный `zstd` работает в 2 раза быстрее многопоточного `gzip` (`pigz`). 
В том числе и потому, что `.zst` файл на 23% меньше, чем `.gz`.
Чем меньше размер файла, тем быстрее он запишется на диск.

**--format=custom**
```
petrov@my-server:/mnt/data/tmp/dump$ time pg_dump -U postgres --host=127.0.0.1 --format=custom --clean --if-exists --dbname=my_database --file=my_database.dump --compress=5
real    0m48.406s
user    0m45.934s
sys    0m0.725s
```
Встроенная однопоточная `gzip` компрессия работает от 1.5 (`pigz`) до 3-х (`zstd`) раз медленнее многопоточной. 

**--format=directory**
```
petrov@my-server:/mnt/data/tmp/dump$ rm -f -R my_database_dir.dump && time pg_dump -U postgres --host=127.0.0.1 --format=directory --clean --if-exists --dbname=my_database --file=my_database_dir.dump --compress=5 --jobs=1
real    0m47.390s
user    0m42.946s
sys    0m0.704s

petrov@my-server:/mnt/data/tmp/dump$ rm -f -R my_database_dir.dump && time pg_dump -U postgres --host=127.0.0.1 --format=directory --clean --if-exists --dbname=my_database --file=my_database_dir.dump --compress=5 --jobs=12
real    0m33.258s
user    0m53.595s
sys    0m0.848s
```
Встроенная многопоточная `gzip` компрессия работает в 1.5 раза быстрее однопоточной.

**CPU и версии**
```
petrov@my-server:/mnt/data/tmp/dump$ nproc
12

petrov@my-server:~$ pzstd --version
PZSTD version: 1.4.4.

petrov@my-server:~$ pigz --version
pigz 2.4
```

**Размеры файлов и папок**
```
petrov@my-server:/mnt/data/tmp/dump$ ll
total 1289156
drwxrwxrwx 3 root        root             4096 Dec  5 19:49 ./
drwxr-xr-x 5 root        root             4096 Dec  5 17:07 ../
-rw-rw-r-- 1 petrov petrov 477758999 Dec  5 19:50 my_database.dump
-rw-rw-r-- 1 petrov petrov 477673867 Dec  5 18:50 my_database.sql.gz
-rw-rw-r-- 1 petrov petrov 364630806 Dec  5 18:45 my_database.sql.zst
drwx------ 2 petrov petrov      4096 Dec  5 19:45 my_database_dir.dump/

petrov@my-server:/mnt/data/tmp/dump$ du -b my_database_dir.dump
477178663    my_database_dir.dump
```

По итогам нескольких замеров установлено, что для `gzip` уровень компрессии 5 является оптимальным:
* Если делать меньше, то размер файлов увеличивается, а длительность работы остаётся без изменений.
* Если делать больше, то размер файлов уменьшается, а длительность работы увеличивается.

## pg_restore

**Восстановление из дампа в формате директории**
```
petrov@test-pg:~/dump_test$ time pg_restore --username=postgres --dbname=my_database_tmp --clean --if-exists --jobs=1 my_database_dir.dump
real    1m29,921s
user    0m12,874s
sys    0m2,907s

petrov@test-pg:~/dump_test$ time pg_restore --username=postgres --dbname=my_database_tmp --clean --if-exists --jobs=5 my_database_dir.dump
real    0m43,100s
user    0m12,773s
sys    0m3,019s
```
Восстановление из дампа во многопоточном (параллельном) режиме работает в 2 раза быстрее однопоточного!

**Progress bar**
```bash
time (pg_restore --username=postgres --dbname=my_database_tmp --clean --if-exists --jobs=10 --verbose my_database.dir.dump 2>&1 \
      | grep -E '(processing item|finished item)' \
      | pv -l -s $(pg_restore -l my_database.dir.dump | grep -c '^[^;]') \
      > /dev/null)
```
See also https://www.google.com/search?q=pg_restore+pg_dump+pv
