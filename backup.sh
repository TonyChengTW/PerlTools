#-----------------
# Writer : Mico Cheng
# Version: 2004052501
# use for : backup maillog & etc to EMC Storage (200g_1)
# Host : pop02
#-----------------
#!/usr/bin/bash
backup_me()
{
  TODAY=`date +%Y%m%d`
  YESTERDAY=`expr $TODAY - 1`
  cp `/usr/local/bin/find /export/home/logs/syslog/ -type f -mtime -2` /backup/maillog/pop02-maillog-`echo $YESTERDAY`.gz 
  /usr/local/bin/tar --ignore-failed-read -zcvBpf /backup/etc/pop02-etc-`date +%Y%m%d`.tar.gz /etc 2>>/tmp/backup-fail.log || return $?
  /usr/local/bin/tar --ignore-failed-read -zcvBpf /backup/etc/pop02-postfix-`date +%Y%m%d`.tar.gz /var/postfix/config 2>>/tmp/backup-fail.log || return $?
  /usr/local/bin/tar --ignore-failed-read -zcvBpf /backup/etc/pop02-mico-tool-`date +%Y%m%d`.tar.gz /export/home/mico 2>>/tmp/backup-fail.log || return $?
}

backup_me

/usr/local/bin/chmod 600 /backup/ufsdump/*
/usr/local/bin/chmod 600 `find /backup -type f`
/usr/local/bin/chmod 700 `find /backup -type d`
/usr/local/bin/chown -R backup_acc:users /backup
