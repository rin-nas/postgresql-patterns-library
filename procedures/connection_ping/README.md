# Тестирование потери установленного соединения к PostgreSQL

```bash
psql -U postgres -q -X -c "\echo 'Press CTRL+C to stop'" -c "\conninfo" -f connection_ping.sql -c "call connection_ping(1000, 0.5)" -h <host> -p <port>
```
[connection_ping.sql](connection_ping.sql)
