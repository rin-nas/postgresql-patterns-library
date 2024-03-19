# Удобное цветное приглашение командной строки в psql

![psqlrc primary](psqlrc.primary.png)
![psqlrc standby](psqlrc.standby.png)

Отображается:
1. дата-время с часовой зоной
1. роль сервера: основной мастер (primary) или реплика (standby)
1. версия мажорная и минорная
1. имя пользователя, под которым подключились
1. название хоста
1. порт
1. название базы данных
1. pid процесса в СУБД

Как установить: https://postgrespro.ru/docs/postgresql/16/app-psql#APP-PSQL-FILES-PSQLRC

Файл с конфигурацией: [psqlrc](psqlrc)