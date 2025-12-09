# TODO

1. Сделать проверку pg_checksums опциональной (добавить настройку в конфигурационный файл?), потому что pg_basebackup при создании рез. копий уже проверяет контрольные суммы, если они включены.
   В gpg в командной строке вместо пароля (--passphrase) использовать чтение из файла (--passphrase_file) pg_gpg_passphrase.
   Вместо команды `ionice -c2 -n7 -- nice -n19 --` использовать соответствующие настройки Systemd? \
   https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html \
   https://unix.stackexchange.com/questions/788554/set-highest-cpu-and-io-priority-for-a-systemd-service (пример)
1. В функции валидации корректности восстанавливаемости СУБД из рез. копии после выполнения pg_controldata добавить проверку, что СУБД корректно завершила работу
   ```
   pg_controldata | grep state
   Database cluster state: shut down
   ```
1. Подумать над приоритетом выбора сервера, с которого делать бекап из-за [комментария](https://habr.com/ru/articles/506610/#comment_21736832) Димы Бородина: \
   "Вот есть у нас кластер, типа patroni. В нём есть primary, и какие-то реплики.
   Сейчас у нас в питонячем скрипте реплики координируются через ЗК чтобы выбрать какой из узлов снимает бекап: в последнюю очередь с primary, но лучше с реплики.
   Из реплик лучше выбирать не ту что в syncronous_standby_names. Среди прочих нужно выбрать реплику с максимальным LSN. Нетривиально, да?"
