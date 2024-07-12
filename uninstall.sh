#!/bin/bash

# Désinstallation des paquets installés
echo "Removing installed packages..."
apt-get remove --purge -y apache2 php7.4 libapache2-mod-php7.4 php7.4-mysql graphviz aspell git
apt-get remove --purge -y clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql ghostscript
apt-get remove --purge -y php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring
apt-get remove --purge -y mariadb-server mariadb-client

# Suppression des répertoires Moodle
echo "Removing Moodle directories..."
rm -rf /var/www/moodle
rm -rf /var/www/moodledata

# Suppression des configurations Apache
echo "Removing Apache configurations..."
a2dissite moodle.conf
rm /etc/apache2/sites-available/moodle.conf
systemctl reload apache2

# Suppression de la base de données et de l'utilisateur Moodle
echo "Removing Moodle database and user..."
MYSQL_ROOT_PASSWORD="your_mysql_root_password"  # Assurez-vous d'utiliser le bon mot de passe root
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
DROP DATABASE IF EXISTS moodle;
DROP USER IF EXISTS 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# Suppression du cron job
echo "Removing cron job..."
crontab -u www-data -l | grep -v "/var/www/moodle/admin/cli/cron.php" | crontab -u www-data -

echo "Moodle uninstallation completed successfully."
