#!/usr/bin/bash
/usr/local/bin/find /backup/maillog/ -type f -mtime +183 -exec rm -f - {} \;
/usr/local/bin/find /backup/db/ -type f -mtime +63 -exec rm -f - {} \;
/usr/local/bin/find /backup/etc/ -type f -mtime +183 -exec rm -f - {} \;
/usr/local/bin/find /backup/ezml/ -type f -mtime +10 -exec rm -f - {} \;
