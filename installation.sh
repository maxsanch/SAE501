#!/bin/bash

# verifier si le server accepte la restor avant, verifier si les inforamtions de la BDD ont changer et transferer le dossier perso

echo "modification de la memoire..."

dd if=/dev/zero of=/swapfile1 bs=1024 count=1048576
chmod 600 /swapfile1 
mkswap /swapfile1
swapon /swapfile1

REP_SWAPFILE=""
# Vérifie si la ligne existe déjà dans /etc/fstab
if ! grep -q "/swapfile1" /etc/fstab; then
    echo "/swapfile1 none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null
    
    REP_SWAPFILE="Ligne ajoutée à /etc/fstab"
    echo "Ligne ajoutée à /etc/fstab"
else
    REP_SWAPFILE="SwapFile : La ligne existe déjà, elle n'a pas été ajoutée."
    echo "La ligne existe déjà dans /etc/fstab"
fi

echo "update du vps..."
sudo apt update -y
sudo apt install -y vim

echo "ajout d'utilisateur..."

# # Créer l’utilisateur avec son mot de passe passé en argument

REP_USER=""

if sudo useradd -m -s /bin/bash -G sudo maxence; then
    echo "maxence:$1" | sudo chpasswd
    echo "modification du service SSH..."
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

    REP_USER="l'utilisateur à bien été crée"
else
    REP_USER="l'utilisateur était déjà crée ou une erreur est survenue"
fi

echo "$REP_USER"

echo "redémarage du service ssh..."
sudo systemctl restart ssh

###########################
##installation du serveur##
###########################

echo "mise en place du stack lamp..."

REP_APACHE=""
REP_PHP=""
REP_MARIADB=""

if sudo apt install apache2 -y; then
    REP_APACHE="apache installé avec succès";
else
    REP_APACHE="une erreur est survenue lors de  l'installation de apache2";
fi

if sudo apt install php -y; then
    REP_PHP="php installé avec succès";
else
    REP_PHP="une erreur est survenue lors de  l'installation de PHP";
fi

if sudo apt install mariadb-server -y; then
    REP_MARIADB="mariadb installé avec succès";
else
    REP_MARIADB="maria db a rencontré une erreur lors de l'installation";
fi

echo "$REP_APACHE"
echo "$REP_PHP"
echo "$REP_MARIADB"

REP_SECURE=""
REP_PHPMYADMIN=""

if dpkg -l | grep -q mariadb-server; then
    echo "MariaDB est installée, sécurisation en cours..."
    sudo systemctl start mariadb
    echo "sécurisation de mysql..."

    if \
    sudo mysql -e "DELETE FROM mysql.user WHERE User='';" && \
    sudo mysql -e "DROP DATABASE IF EXISTS test;" && \
    sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" && \
    sudo mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User='root';" && \
    sudo mysql -e "FLUSH PRIVILEGES;"; then

        REP_SECURE="Sécurisation MariaDB effectuée avec succès !"
    else
        REP_SECURE="Une erreur est survenue lors de la sécurisation de MariaDB"
    fi

    echo "$REP_SECURE"

    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password $1" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password $1" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password $1" | sudo debconf-set-selections

    if sudo apt install -y phpmyadmin; then
        REP_PHPMYADMIN="phpmyadmin a été installé"

        echo "création d'un utilisateur..."
        # Variables (modifiable facilement)
        DB_USER="maxence"

        # Création de l'utilisateur MySQL et attribution des droits
        sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '$1';"
        sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost';"
        sudo mysql -e "FLUSH PRIVILEGES;"
    else
        REP_PHPMYADMIN="phpmyadmin a rencontré une erreur lors de l'installation"
    fi

    echo "$REP_PHPMYADMIN"
else
    echo "MariaDB n'est pas installée. Installation requise avant la sécurisation et l'installation de PHPMYADMIN."
fi

sudo a2enmod rewrite
sudo systemctl restart apache2


echo "récupération des dossiers..."
cd /var/www/html

mkdir perso

cd /home

cd /etc/apache2/sites-available

wget "https://raw.githubusercontent.com/maxsanch/SAE501/refs/heads/main/perso-ssl.conf"

wget "https://raw.githubusercontent.com/maxsanch/SAE501/refs/heads/main/perso.conf"

REP_SITE=""

if sudo a2ensite perso.conf; then
    REP_SITE="le site a bien été configuré"
else
    REP_SITE="la configuration du site a echouée"
fi

REP_SSL=""

if sudo a2enmod ssl; then 
    REP_SSL="le module SSL a bien été activé"
else
    REP_SSL="une erreur est survenue lors de l'activation du module SSL"
fi

echo "activation du site..."

REP_SITESSL=""

if sudo a2ensite perso-ssl.conf; then
    REP_SITESSL="le site est opérationnel avec SSL !"
else
    REP_SITESSL="la configuration du site SSL n'a pas fonctionnée, veuillez le faire manuellement."
fi

echo "redemarage de apache..."
sudo systemctl reload apache2

cd /var/www/html/perso

echo "recuperation du fichier prestashop..."

REP_GETPRESTA=""

if wget https://assets.prestashop3.com/dst/edition/corporate/9.0.0-1.0/prestashop_edition_classic_version_9.0.0-1.0.zip?source=docker; then
    REP_GETPRESTA="prestashop recupéré"
else
    REP_GETPRESTA="La récupération du prestashop a échouée"
fi

echo "$REP_GETPRESTA"

REP_MOVE=""

if mv 'prestashop_edition_classic_version_9.0.0-1.0.zip?source=docker' prestashop.zip; then
    REP_MOVE="le déplacement du fichier a été effectué"
else
    REP_MOVE="le déplacement du fichier a échoué"
fi

echo "$REP_MOVE"

sudo apt update

REP_UNZIP=""

if sudo apt install unzip; then
    REP_UNZIP="installation de UNZIP effectuée"
else
    REP_UNZIP="m'installation de UNZIP a échouée"
fi

echo "$REP_UNZIP"

REP_UNZIPDONE=""

if unzip -o prestashop.zip; then
    REP_UNZIPDONE="dézippage de prestashop effectué"
else
    REP_UNZIPDONE="le dezippage de prestashop a echoué"
fi

echo "$REP_UNZIPDONE"

chown www-data *
chown www-data .

echo "dezippage du projet..."

REP_UNZIPDONETWO=""

if unzip -o prestashop.zip; then
    REP_UNZIPDONETWO="le second dezippage a été effectué"
else
    REP_UNZIPDONETWO="le second dezippage a échoué"
fi

echo "$REP_UNZIPDONETWO"

sudo apt update
sudo apt install -y unzip php-intl

mysql -u maxence -p$1 -e "CREATE DATABASE SAEShop;"

sudo chown -R www-data:www-data /var/www/html/perso
sudo find /var/www/html/perso -type d -exec chmod 755 {} \;
sudo find /var/www/html/perso -type f -exec chmod 644 {} \;

echo "recherche index cli..."

cd /var/www/html/perso/install

REP_CLI=""

if php index_cli.php --domain=ip87-106-123-72.pbiaas.com --db_server=127.0.0.1 --db_name=SAEShop --db_user=maxence  --db_password=$1  --prefix=myshop_ --email=maxence.sanchez05@gmail.com --password=$1; then
    REP_CLI="installation CLi effectuée"
else
    REP_CLI="l'installation CLI a échouée."
fi

cd /var/www/html/perso

sudo rm -r install

echo "Activation du HTTPS dans PrestaShop..."
DB_NAME="SAEShop"
DB_PREFIX="myshop_"

sudo mysql -u $DB_USER -p$1 -e "UPDATE ${DB_NAME}.${DB_PREFIX}configuration SET value='1' WHERE name='PS_SSL_ENABLED';"
sudo mysql -u $DB_USER -p$1 -e "UPDATE ${DB_NAME}.${DB_PREFIX}configuration SET value='1' WHERE name='PS_SSL_ENABLED_EVERYWHERE';"

sudo systemctl restart apache2

USERFTP="maxenceftp"
GROUP="www-data"
CHROOT_DIR="/var/www"

echo ">> Création de l'utilisateur $USERFTP dans le groupe $GROUP..."
useradd -M -g "$GROUP" -s /usr/sbin/nologin "$USERFTP"

# --- ATTRIBUTION DU MOT DE PASSE ---
echo ">> Définition du mot de passe..."
echo "$USERFTP:$1" | chpasswd

if id "$USERFTP" >/dev/null 2>&1; then
    echo "Utilisateur $USERFTP créé avec succès."
else
    echo "Erreur : échec de la création de l'utilisateur $USERFTP."
    exit 1
fi

# --- SUPPRESSION DU HOME DIRECTORY ---
echo ">> Suppression du dossier personnel (si existant)..."
rm -rf "/home/$USERFTP"

# --- MODIFICATION DU FICHIER SSHD_CONFIG ---
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.backup_$(date +%F_%H-%M-%S)"

echo ">> Sauvegarde de la configuration SSH existante dans $BACKUP_FILE"
cp "$SSHD_CONFIG" "$BACKUP_FILE"

echo ">> Mise à jour de la configuration SSH..."

# Commente la ligne Subsystem existante si elle n'est pas déjà commentée
sed -i 's/^\(Subsystem[[:space:]]\+sftp[[:space:]]\+\)/#\1/' "$SSHD_CONFIG"

# Ajoute la nouvelle directive Subsystem si elle n'existe pas déjà
grep -q "^Subsystem sftp internal-sftp" "$SSHD_CONFIG" || echo "Subsystem sftp internal-sftp" >> "$SSHD_CONFIG"

# Ajout du bloc Match User à la fin du fichier (s’il n’existe pas déjà)
if ! grep -q "Match User $USERFRP" "$SSHD_CONFIG"; then
    cat <<EOF >> "$SSHD_CONFIG"

Match User $USERFTP
    ChrootDirectory $CHROOT_DIR
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF
fi

# --- VÉRIFICATION DE LA CONFIGURATION ---
echo ">> Vérification de la configuration SSH..."
if sshd -t 2>/dev/null; then
    echo "Syntaxe correcte"
else
    echo "Erreur de syntaxe dans $SSHD_CONFIG"
    echo "Restauration du fichier de sauvegarde..."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    exit 1
fi

# --- RECHARGEMENT DU SERVICE SSH ---
echo ">> Redémarrage du service SSH..."
systemctl restart sshd

if systemctl is-active --quiet sshd; then
    echo "Le service SSH a redémarré avec succès"
else
    echo "Erreur lors du redémarrage de SSH"
    echo "Vérifiez la configuration manuellement."
    exit 1
fi

echo "Configuration SFTP pour $USERFTP terminée avec succès."

echo ">> Sécurisation du dossier chroot et attribution des droits sur /var/www/html..."

# Le dossier chroot /var/www doit appartenir à root et ne pas être modifiable
chown root:root /var/www
chmod 755 /var/www

# Donner la propriété du dossier HTML au groupe www-data
echo ">> Attribution du groupe www-data à /var/www/html et à tout son contenu..."
chgrp -R www-data /var/www/html

# Donner le droit d'écriture au groupe propriétaire
echo ">> Autorisation d'écriture pour le groupe sur /var/www/html..."
chmod -R g+w /var/www/html

echo ">> Vérification des droits appliqués :"
ls -ld /var/www /

###########################################
# RESTAURATION DU BACKUP (site + base)
###########################################

echo "==> Début de la restauration du backup distant..."

# Variables de connexion
BACKUP_USER="backupsite"
BACKUP_HOST="87.106.123.59"
BACKUP_DIR="/home/backupsite/backup"
DEST_DIR="/var/www/html/perso"
PASS="$1"  # mot de passe passé en paramètre

DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$DATE] Début de la restauration..."

# Vérification du mot de passe
if [ -z "$PASS" ]; then
  echo "[$DATE] Aucun mot de passe fourni !"
  exit 1
fi

# Liste des dossiers à restaurer
FOLDERS=("themes" "config" "modules" "img" "upload" "download" "mails")

for folder in "${FOLDERS[@]}"; do
  echo "[$DATE] Restauration du dossier $folder..."
  # Téléchargement du dossier depuis le serveur distant
  sshpass -p "$PASS" scp -o StrictHostKeyChecking=no -r ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DIR}/${folder} ${DEST_DIR}

  echo "[$DATE] Dossier $folder restauré."
done

# Restauration des fichiers simples (.htaccess et robots.txt)
FILES=(".htaccess" "robots.txt")
for file in "${FILES[@]}"; do
  echo "[$DATE] Restauration du fichier $file..."
  sshpass -p "$PASS" scp -o StrictHostKeyChecking=no ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DIR}/${file} ${DEST_DIR}/${file}
  echo "[$DATE] Fichier $file restauré."
done

if sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no ${BACKUP_USER}@${BACKUP_HOST} "[ -f ${BACKUP_DIR}/SAEShop.sql ]"; then
  echo "[$DATE] Restauration de la base de données..."
  sshpass -p "$PASS" scp -o StrictHostKeyChecking=no ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DIR}/SAEShop.sql /tmp/
  mysql -u maxence -p"$PASS" SAEShop < /tmp/SAEShop.sql
  echo "[$DATE] Base de données restaurée."
fi

echo "[$DATE] Restauration terminée avec succès !"

sudo apt update
sudo apt install certbot python3-certbot-apache -y

sudo certbot --apache \
  -d ip87-106-123-72.pbiaas.com \
  --non-interactive \
  --agree-tos \
  --email maxence.sanchez05@gmail.com \
  --redirect \
  --no-eff-email

echo "==> Installation de cron et sshpass..."
apt-get update
apt-get install -y cron sshpass

# Démarrer et activer cron
systemctl enable cron
systemctl start cron

wget "https://raw.githubusercontent.com/maxsanch/SAE501/refs/heads/main/backup.sh"
chmod +x backup.sh

CRON_JOB="0 3 * * * /root/backup.sh '$1'"

( crontab -l 2>/dev/null | grep -Fv "/root/backup.sh" ; echo "$CRON_JOB" ) | crontab -

echo "cron mis en place"

echo "-- normalement, c'est bon !--"
echo "$REP_SWAPFILE"
echo "$REP_USER"
echo "$REP_APACHE"
echo "$REP_PHP"
echo "$REP_MARIADB"
echo "$REP_SECURE"
echo "$REP_PHPMYADMIN"
echo "$REP_SITE"
echo "$REP_SSL"
echo "$REP_SITESSL"
echo "$REP_GETPRESTA"
echo "$REP_MOVE"
echo "$REP_UNZIP"
echo "$REP_UNZIPDONE"
echo "$REP_UNZIPDONETWO"
echo "$REP_CLI"