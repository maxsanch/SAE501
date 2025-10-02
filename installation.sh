# #!/bin/bash

echo "modification de la memoire..."

dd if=/dev/zero of=/swapfile1 bs=1024 count=1048576
chmod 600 /swapfile1 
mkswap /swapfile1
swapon /swapfile1

echo "update du vps..."
sudo apt update -y
sudo apt install -y vim

echo "ajout d'utilisateur..."

# # Créer l’utilisateur avec son mot de passe passé en argument
sudo useradd -m -s /bin/bash -G sudo maxence
echo "maxence:$1" | sudo chpasswd

echo "modification du service SSH..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

echo "redémarage du service ssh..."
sudo systemctl restart ssh

###########################
##installation du serveur##
###########################

echo "mise en place du stack lamp..."
sudo apt install apache2 -y
sudo apt install php -y
sudo apt install mariadb-server -y

echo "sécurisation de mysql..."

sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User='root';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $1" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $1" | sudo debconf-set-selections

sudo apt install -y phpmyadmin

echo "création d'un utilisateur..."
# Variables (modifiable facilement)
DB_USER="maxence"

# Création de l'utilisateur MySQL et attribution des droits
sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '$1';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

sudo a2enmod rewrite
sudo systemctl restart apache2

echo "récupération des dossiers..."
cd /var/www/html

mkdir perso

cd /home

cd /etc/apache2/sites-available

wget "https://raw.githubusercontent.com/maxsanch/SAE501/refs/heads/main/perso.conf"
wget "https://raw.githubusercontent.com/maxsanch/SAE501/refs/heads/main/perso-ssl.conf"

sudo a2ensite perso.conf

sudo systemctl reload apache2

sudo a2enmod ssl

echo "activation du site..."
sudo a2ensite perso-ssl.conf

echo "redemarage de apache..."
sudo systemctl reload apache2

cd /var/www/html/perso

echo "recuperation du fichier prestashop..."
wget https://assets.prestashop3.com/dst/edition/corporate/9.0.0-1.0/prestashop_edition_classic_version_9.0.0-1.0.zip?source=docker
mv 'prestashop_edition_classic_version_9.0.0-1.0.zip?source=docker' prestashop.zip
echo "recup ok"

sudo apt update
sudo apt install unzip

unzip -o prestashop.zip

chown www-data *
chown www-data .

echo "dezippage du projet..."
unzip -o prestashop.zip

sudo apt update
sudo apt install -y unzip php-intl

sudo apt restart apache2

mysql -u maxence -p$1 -e "CREATE DATABASE SAEShop;"

sudo chown -R www-data:www-data /var/www/html/perso
sudo find /var/www/html/perso -type d -exec chmod 755 {} \;
sudo find /var/www/html/perso -type f -exec chmod 644 {} \;

php index_cli.php --domain=www.prestashopexo.com --db_server=127.0.0.1 --db_name=SAEShop --db_user=maxence  --db_password=$1  --prefix=myshop_ --email=maxence.sanchez05@gmail.com --password=$1

sudo apt restart apache2

echo "-- normalement, c'est bon !--"

# sudo useradd -m installationftp

# echo "installation:Mj89si72jk*" | sudo chpasswd

# sudo adduser installationftp www-data

# cd /home

# sudo rm -rf installationftp

# # Sauvegarde du fichier SSH avant modification
# sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# # 1️⃣ Commente la ligne Subsystem SFTP existante
# sudo sed -i 's/^Subsystem sftp /#&/' /etc/ssh/sshd_config

# # 2️⃣ Ajoute la ligne Subsystem interne si elle n'existe pas déjà
# grep -qxF 'Subsystem sftp internal-sftp' /etc/ssh/sshd_config || \
#     echo 'Subsystem sftp internal-sftp' | sudo tee -a /etc/ssh/sshd_config

# # 3️⃣ Ajoute la configuration spécifique pour l'utilisateur tata
# sudo bash -c "cat >> /etc/ssh/sshd_config <<EOF

# Match User installationftp
#     ChrootDirectory /var/www
#     ForceCommand internal-sftp
#     AllowTcpForwarding no
#     X11Forwarding no
# EOF"

# # 4️⃣ Redémarre le service SSH pour appliquer les modifications
# sudo systemctl restart sshd