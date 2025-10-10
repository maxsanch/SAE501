#!/bin/bash
# backup_presta.sh — script automatique de backup PrestaShop

# Dossiers et accès
SRC="/var/www/html/perso/themes/classic"
DEST_USER="backupsite"
DEST_HOST="87.106.123.59"
DEST_PATH="/home/backupsite/backup"

# Date du jour (pour les logs)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="/var/log/backup_presta.log"

# Exécution
echo "[$DATE] Début du transfert..." >> "$LOGFILE"
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -r "$SRC" ${DEST_USER}@${DEST_HOST}:${DEST_PATH} >> "$LOGFILE" 2>&1

if [ $? -eq 0 ]; then
  echo "[$DATE] ✅ Sauvegarde réussie" >> "$LOGFILE"
else
  echo "[$DATE] ❌ Erreur lors du transfert" >> "$LOGFILE"
fi