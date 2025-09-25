# Монтирование сетевой папки /mnt/backup_db (на примере)

> [!NOTE]
> Сетевую папку обычно монтируют системные администраторы, а не DBA.

```bash
# хотим на сервере sp-ek-db-pr02 сделать папку, как на сервере sp-ek-db-pr03
root@sp-ek-db-pr03 ~ $ df -H
...
//sp-bkp-bpr-pr03.cplsb.ru/Backup_DB/EK   80T   24T   56T   31% /mnt/backup_db
...
 
# копируем содержимое файла в буфер обмена 1
root@sp-ek-db-pr03 ~ $ cat ~/.smbclient
username=srv_bpk_ek
password=*censored*
domain=cplsb.ru
 
# копируем строку из файла в буфер обмена 2
root@sp-ek-db-pr03 ~ $ cat /etc/fstab
...
# backup DB
//sp-bkp-bpr-pr03.cplsb.ru/Backup_DB/EK /mnt/backup_db cifs user,rw,credentials=/root/.smbclient,dir_mode=0750,file_mode=0640,uid=postgres,gid=postgres,nofail 0 0
...
 
#----------------------------------------------------------------------------------------------------------------------------

# инсталлируем
root@sp-ek-db-pr02 ~ $ dnf -y install cifs-utils
 
# создаём папку
root@sp-ek-db-pr02 ~ $ mkdir -p /mnt/backup_db && chmod 770 /mnt/backup_db && chown postgres:postgres /mnt/backup_db
  
# создаём файл из буфера обмена 1
root@sp-ek-db-pr02 ~ $ nano -c ~/.smbclient && chmod 600 ~/.smbclient
 
# добавляем строку из буфера обмена 2
root@sp-ek-db-pr02 ~ $ nano -c /etc/fstab
 
# автоматическое монтирование
root@sp-ek-db-pr02 ~ $ mount -a && systemctl daemon-reload
 
# ручное монтирование без /etc/fstab (при необходимости)
# root@sp-ek-db-pr02 ~ $ mount.cifs //sp-bkp-bpr-pr03.cplsb.ru/Backup_DB/EK /mnt/backup_db -o user,rw,credentials=/root/.smbclient,dir_mode=0750,file_mode=0640,uid=postgres,gid=postgres,nofail
 
# если будет ошибка, то смотрим системный журнал
root@sp-ek-db-pr02 ~ $ tail -n20 /var/log/messages
 
# если нет доступов, проверяем доступность портов
# root@sp-ek-db-pr02 ~ $ nmap sp-bkp-bpr-pr03 -p 139 # DEPRECATED
root@sp-ek-db-pr02 ~ $ nmap sp-bkp-bpr-pr03 -p 445
 
# как отмонтировать, при необходимости
root@sp-ek-db-pr02 ~ $ umount /mnt/backup_db
```
