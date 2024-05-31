# Тестирование потери установленного соединения к PostgreSQL

Как протестировать?

1. Запустить команду в терминале 1
1. Разорвать соединение к СУБД в терминале 2
1. Посмотреть результат в терминале 1. В случае потери соединения вывод уведомлений (ping) приостановится (в этом случае `psql` "зависает") или явно возвратится ошибка

```bash
# устанавливаем psql, при необходимости
sudo dnf -y install postgresql-14-14.5 postgresql-14-libs-14.5
  
# создаём файл .pgpass, при необходимости
nano ~/.pgpass
 
# передаём в application_name основной IP текущего сервера, т.к. запрос может проходить через прокси
psql -q -X -U postgres -d "application_name='psql $(hostname -I | cut -f1 -d' ')'" \
  -c "\echo 'Press CTRL+C to stop'" -c "\conninfo" -f connection_ping.sql -c "call connection_ping(1000, 1.0)" \
  -h <host> -p <port>
```
[connection_ping.sql](connection_ping.sql)

## TODO

В случае "зависания" `psql` можно ещё попробовать заглянуть в `pg_stat_activity` и термирировать процесс (самоуничтожение), если он долго ожидает клиента.
