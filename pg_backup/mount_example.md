# Монтирование сетевой папки /mnt/backup_db (на примере)

> [!NOTE]
> Сетевую папку обычно монтируют системные администраторы, а не DBA.

```bash
# хотим на сервере srv2 сделать папку, как на сервере srv3
root@srv3 ~ $ df -H
...
//srv-bkp/Backup_DB/EK   80T   24T   56T   31% /mnt/backup_db
...
 
# копируем содержимое файла в буфер обмена 1
root@srv3 ~ $ cat ~/.smbclient
username=srv_bpk_ek
password=*censored*
domain=cplsb.ru
 
# копируем строку из файла в буфер обмена 2
root@srv3 ~ $ cat /etc/fstab
...
# backup DB
//srv-bkp/Backup_DB/EK /mnt/backup_db cifs user,rw,credentials=/root/.smbclient,dir_mode=0750,file_mode=0640,uid=postgres,gid=postgres,nofail 0 0
...
 
#----------------------------------------------------------------------------------------------------------------------------

# инсталлируем
root@srv2 ~ $ dnf -y install cifs-utils
 
# создаём папку
root@srv2 ~ $ mkdir -p /mnt/backup_db && chmod 770 /mnt/backup_db && chown postgres:postgres /mnt/backup_db
  
# создаём файл из буфера обмена 1
root@srv2 ~ $ nano -c ~/.smbclient && chmod 600 ~/.smbclient
 
# добавляем строку из буфера обмена 2
root@srv2 ~ $ nano -c /etc/fstab
 
# автоматическое монтирование
root@srv2 ~ $ mount -a && systemctl daemon-reload
 
# ручное монтирование без /etc/fstab (при необходимости)
# root@srv2 ~ $ mount.cifs //srv-bkp/Backup_DB/EK /mnt/backup_db -o user,rw,credentials=/root/.smbclient,dir_mode=0750,file_mode=0640,uid=postgres,gid=postgres,nofail
 
# если будет ошибка, то смотрим системный журнал
root@srv2 ~ $ tail -n20 /var/log/messages
 
# если нет доступов, проверяем доступность портов
# root@srv2 ~ $ nmap sp-bkp-bpr-pr03 -p 139 # DEPRECATED
root@srv2 ~ $ nmap sp-bkp-bpr-pr03 -p 445
 
# как отмонтировать, при необходимости
root@srv2 ~ $ umount /mnt/backup_db
```
