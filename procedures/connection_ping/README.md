# Тестирование потери установленного соединения к PostgreSQL

Как протестировать?

1. Запустить команду в терминале 1
1. Разорвать соединение к СУБД в терминале 2
1. Посмотреть результат в терминале 1

```bash
psql -U postgres -q -X -c "\echo 'Press CTRL+C to stop'" -c "\conninfo" -f connection_ping.sql -c "call connection_ping(1000, 0.5)" -h <host> -p <port>
```
[connection_ping.sql](connection_ping.sql)

## TODO

Psql может "зависнуть" после потери соединения к СУБД. Можно ещё заглянуть в pg_stat_activity и термирировать процесс (самоуничтожение), если он долго ожидает клиента.
