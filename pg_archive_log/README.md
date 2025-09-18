# Инсталляция сервиса архивирования log файлов PostgreSQL

## Описание

[Systemd](https://en.wikipedia.org/wiki/Systemd) сервис, который запускается 1 раз в сутки:
1. удаляет файлы старше N дней
1. удаляет файлы нулевого размера старше K дней
1. архивирует несжатые файлы старше М дней, если размер файла > S килобайт

Команда для архивации (сжатия) файлов выполняется в один поток с самым низким приоритетом (для минимизации рисков влияния на работающую СУБД).

## Требования

Место на диске обычно ограничено и не бесплатное. За длительный период хранения файлов их необходимо сжимать как можно сильнее, но не потребляя слишком много ресурсов (CPU, память). В данном случае степень сжатия важнее скорости сжатия и распаковки (можно подождать).

## Предусловия

```ini
log_destination = 'csvlog' #опционально
log_directory = '/var/log/postgresql/16' #для надёжности, папку /var/log лучше сделать в отдельном разделе ФС с квотой свободного места
log_filename = 'postgresql-%Y-%m-%d.log'
```

## Инсталляция и настройка

```bash
# создаём файлы
sudo nano /etc/systemd/system/pg_archive_log.timer && \
sudo nano /etc/systemd/system/pg_archive_log.service
 
# активируем и добавляем в автозагрузку
sudo systemctl daemon-reload  && \
sudo systemctl enable pg_archive_log.timer && \
sudo systemctl enable pg_archive_log
 
# запускаем
sudo systemctl start pg_archive_log.timer && \
sudo systemctl start pg_archive_log
 
# проверяем статус
sudo systemctl status pg_archive_log.timer && \
sudo systemctl status pg_archive_log
 
# получаем список активных таймеров, д.б. указана дата-время следующего запуска!
systemctl list-timers | grep -P 'NEXT|pg_archive_log'
```

**Файлы**
1. [`/etc/systemd/system/pg_archive_log.timer`](pg_archive_log.timer)
2. [`/etc/systemd/system/pg_archive_log.service`](pg_archive_log.service)

## Тестирование сжатия

Исходный тестовый файл: `postgresql-2025-09-14.csv` **186,311,281 байт**.\
Сжатие и распаковка в один поток. Распаковка в `/dev/null`.\
Для замеров длительности выполнения и потребления памяти использовалась команда `/usr/bin/time -v COMMAND`.

| Program and compression level | Compression size (bytes)	| Compression size (%)	| Compression duration (s)	| Compression memory (KB)	| Decompression duration (s)	| Decompression memory (KB)	| Rating place |
| :--- | ---:	| ---:	| ---:	| ---:	| ---:	| ---:	| ---: |
| `gzip -9`	   | $\color{#f00}{3,453,449}$	| $\color{#f00}{144\\%}$	| $\color{#090}{1.24}$	 | $\color{#090}{2,416}$	  | $\color{#090}{0.46}$	| $\color{#090}{2,408}$	  | — |
| `zstd -9`	   | $\color{#f00}{2,381,965}$	| 100%	                  | $\color{#090}{1.55}$	 | $\color{#090}{41,580}$	 | $\color{#090}{0.04}$	| $\color{#090}{4,220}$	  | 3 |
| `zstd -14`   | $\color{#f00}{2,449,812}$	| $\color{#f00}{103\\%}$	| $\color{#090}{2.61}$	 | 117,560	                | $\color{#090}{0.04}$	| $\color{#090}{6,436}$	  | — |
| `zstd -19`   | 1,760,829	                | 74% 	                  | $\color{#f00}{77.40}$	| $\color{#f00}{216,512}$	| $\color{#090}{0.08}$	| $\color{#090}{10,444}$	 | — |
| `bzip2 -9`   | 2,138,384	                | 90%	                   | $\color{#f00}{37.70}$	| $\color{#090}{7,944}$	  | $\color{#f00}{3.34}$	| $\color{#090}{5,032}$	  | — |
| `bzip3 -b8`  | $\color{#090}{1,509,780}$	| $\color{#090}{63\\%}$	 | $\color{#090}{2.76}$	 | $\color{#090}{21,212}$	 | 1.99	                | $\color{#090}{52,428}$	 | 1 |
| `bzip3 -b16` | $\color{#090}{1,471,514}$	| $\color{#090}{62\\%}$	 | $\color{#090}{2.71}$	 | $\color{#090}{39,424}$	 | 1.91	                | 101,636	                | 2 |
| `bzip3 -b64` | $\color{#090}{1,412,929}$	| $\color{#090}{59\\%}$	 | $\color{#090}{2.98}$	 | $\color{#f00}{149,040}$	| 2.12	                | $\color{#f00}{396,484}$	| — |
| `xz -9`      | 2,057,736	                | 86%	                   | $\color{#f00}{18,34}$	| $\color{#f00}{629,832}$	| $\color{#090}{0.38}$	| $\color{#090}{16,510}$	 | — |

### Версии ПО

| Program	| Version |
| -------	| ------- |
| [zstd](https://github.com/facebook/zstd)	 | 1.4.4 |
| bzip2	                                    | 1.0.6 |
| [bzip3](https://github.com/iczelia/bzip3)	| 1.3.1 |
| xz, liblzma	                              | 5.2.4 |
