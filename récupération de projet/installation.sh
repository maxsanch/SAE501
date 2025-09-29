#!/bin/bash

sudo apt update

sudo useradd -m maxence

echo "installation:Mj89si72jk*" | sudo chpasswd

systemctl restart ssh

sudo apt install apache2

sudo apt install php

sudo apt install mariadb-server

sudo mysql_secure_installation

sudo n
sudo n
sudo y
sudo y
sudo y
sudo y

# Mise à jour des paquets
sudo apt update -y

# Pré-réponses pour debconf (serveur Apache2 + dbconfig-common + mot de passe vide)
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password " | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password " | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password " | sudo debconf-set-selections

# Installation de phpMyAdmin sans interaction
sudo DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin

# Variables (modifiable facilement)
DB_USER="maxence"
DB_PASS="Mj89si72jk*"

# Création de l'utilisateur MySQL et attribution des droits
sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

sudo useradd -m installationftp

echo "installation:Mj89si72jk*" | sudo chpasswd

sudo adduser installationftp www-data

cd /home

sudo rm -rf installationftp

# Sauvegarde du fichier SSH avant modification
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 1️⃣ Commente la ligne Subsystem SFTP existante
sudo sed -i 's/^Subsystem sftp /#&/' /etc/ssh/sshd_config

# 2️⃣ Ajoute la ligne Subsystem interne si elle n'existe pas déjà
grep -qxF 'Subsystem sftp internal-sftp' /etc/ssh/sshd_config || \
    echo 'Subsystem sftp internal-sftp' | sudo tee -a /etc/ssh/sshd_config

# 3️⃣ Ajoute la configuration spécifique pour l'utilisateur tata
sudo bash -c "cat >> /etc/ssh/sshd_config <<EOF

Match User installationftp
    ChrootDirectory /var/www
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF"

# 4️⃣ Redémarre le service SSH pour appliquer les modifications
sudo systemctl restart sshd

cd /etc/apache2/sites-available

CONF_FILE="/etc/apache2/sites-available/perso.conf"

sudo bash -c "cat > $CONF_FILE <<EOF
<VirtualHost *:80>
    ServerName www.prestashop.fr
    DocumentRoot /var/www/html/prestashop

    <Directory /var/www/html/prestashop>
        AllowOverride All
        Options -Indexes
        Require all granted
    </Directory>
</VirtualHost>
EOF"

cd /var/www/html

mkdir prestashop

# Active le site
sudo a2ensite perso.conf

# Recharge Apache pour prendre en compte la nouvelle conf
sudo systemctl reload apache2

SITE_DIR="/var/www/html/prestashop"


# obtenir prestashop avec le lien
wget https://prestashop.fr/offres-prestashop/classic/ -O prestashop.zip

# Dézipper
unzip prestashop.zip -d $SITE_DIR

# Supprimer le ZIP
rm prestashop.zip

sudo apt install ssl

sudo a2enmod ssl

CONF_FILE_SSL="/etc/apache2/sites-available/perso-ssl.conf"

sudo bash -c "cat > $CONF_FILE_SSL <<EOF
<VirtualHost *:443>
    ServerName www.prestashop.fr
    DocumentRoot /var/www/html/prestashop

    SSLEngine ON
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key


    <Directory /var/www/html/prestashop>
        AllowOverride All
        Options -Indexes
        Require all granted
    </Directory>
</VirtualHost>
EOF"

cd /var/www/html

# Active le site
sudo a2ensite perso-ssl.conf

# Recharge Apache pour prendre en compte la nouvelle conf
sudo systemctl reload apache2