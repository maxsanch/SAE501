#!/bin/bash

# Dossiers et accès
DEST_USER="backupsite"
DEST_HOST="87.106.123.59"
DEST_PATH="/home/backupsite/backup"

# Date du jour (pour les logs)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="/var/log/backup_presta.log"

# Exécution
echo "[$DATE] Début du transfert..." >> "$LOGFILE"
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/themes" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/config" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/modules" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/img" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/upload" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/download" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/mails" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/.htaccess" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/var/www/html/perso/robots.txt" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1

mysqldump -u maxence -p'Mj89si72jk*' SAEShop > /root/SAEShop.sql
sshpass -p "$1" scp -o StrictHostKeyChecking=no -r "/root/SAEShop.sql" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1

if [ $? -eq 0 ]; then
  echo "[$DATE] Sauvegarde réussie" >> "$LOGFILE"
else
  echo "[$DATE] Erreur lors du transfert" >> "$LOGFILE"
fi