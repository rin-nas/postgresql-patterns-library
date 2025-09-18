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
	
| Program and compression level | Compression size (bytes)	| Compression size (%)	| Compression duration (s)	| Compression memory (KB)	| Decompression duration (s)	| Decompression memory (KB)	| Rating place |
| :--- | ---:	| ---:	| ---:	| ---:	| ---:	| ---:	| ---: |
| `gzip -9`	   | 3,453,449	| 144%	|  1.24	|   2,416	| 0.46	|   2,408	| — |
| `zstd -9`	   | 2,381,965	| 100%	|  1.55	|  41,580	| 0.04	|   4,220	| 3 |
| `zstd -14`	  | 2,449,812	| 103%	|  2.61	| 117,560	| 0.04	|   6,436	| — |
| `zstd -19`	  | 1,760,829	|  74%	| 77.40	| 216,512	| 0.08	|  10,444	| — |
| `bzip2 -9`	  | 2,138,384	|  90%	| 37.70	|   7,944	| 3.34	|   5,032	| — |
| `bzip3 -b8`	 | 1,509,780	|  63%	|  2.76	|  21,212	| 1.99	|  52,428	| 1 |
| `bzip3 -b16`	| 1,471,514	|  62%	|  2.71	|  39,424	| 1.91	| 101,636	| 2 |
| `bzip3 -b64`	| 1,412,929	|  59%	|  2.98	| 149,040	| 2.12	| 396,484	| — |
| `xz -9`	     | 2,057,736	|  86%	| 18,34	| 629,832	| 0.38	|  16,510	| — |
