#!/bin/bash

# Définir les mots de passe MySQL
MYSQL_ROOT_PASSWORD="hkURoMtC6j72tU"
MYSQL_MOODLEUSER_PASSWORD="t9frgL0kOjSM8C"
DOMAIN="passboltefrei.site"

# Fonction de nettoyage
clean_installation() {
  echo "Cleaning previous Moodle installation..."

  # Suppression des répertoires Moodle
  rm -rf /var/www/moodle
  rm -rf /var/www/moodledata

  # Suppression des configurations Apache
  a2dissite moodle.conf
  rm /etc/apache2/sites-available/moodle.conf
  systemctl reload apache2

  # Suppression de la base de données et de l'utilisateur Moodle
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
DROP DATABASE IF EXISTS moodle;
DROP USER IF EXISTS 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EOF

  # Suppression du cron job
  crontab -u www-data -l | grep -v "/var/www/moodle/admin/cli/cron.php" | crontab -u www-data -

  echo "Cleaning completed."
}

# Désinstaller toutes les versions de PHP
uninstall_php() {
  echo "Removing all PHP versions..."
  apt-get remove --purge -y 'php*'
  apt-get autoremove -y
  apt-get clean
  echo "All PHP versions removed."
}

# Exécuter le nettoyage préalable
clean_installation

# Désinstaller toutes les versions de PHP
uninstall_php

# Step 1: LAMP server installation
echo "Updating system and installing required packages..."
apt-get update
apt-get install -y software-properties-common

# Ajouter manuellement le PPA d'ondrej/php
echo "Adding ondrej/php PPA..."
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main" > /etc/apt/sources.list.d/ondrej-php.list
echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu focal main" >> /etc/apt/sources.list.d/ondrej-php.list

# Ajouter la clé GPG pour le PPA
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C

# Mettre à jour les paquets et installer PHP 8.1
apt-get update
apt-get install -y apache2 php8.1 libapache2-mod-php8.1 php8.1-mysql graphviz aspell git 
apt-get install -y clamav php8.1-pspell php8.1-curl php8.1-gd php8.1-intl php8.1-mysql ghostscript
apt-get install -y php8.1-xml php8.1-xmlrpc php8.1-ldap php8.1-zip php8.1-soap php8.1-mbstring
apt-get install -y mariadb-server mariadb-client
a2enmod php8.1
systemctl restart apache2
echo "Step 1 has completed."

# Step 2: Clone the Moodle repository into /var/www
echo "Cloning Moodle repository into /var/www/"
echo "Be patient, this can take several minutes."
if [ -d "/var/www/moodle" ]; then
  rm -rf /var/www/moodle
fi
cd /var/www
git clone https://github.com/moodle/moodle.git
cd moodle
git checkout -t origin/MOODLE_401_STABLE
echo "Step 2 has completed."

# Step 3: Directories, ownership, permissions, php.ini changes and virtual hosts 
echo "Setting up directories, ownership, permissions, php.ini changes and virtual hosts..."
if [ -d "/var/www/moodledata" ]; then
  rm -rf /var/www/moodledata
fi
mkdir -p /var/www/moodledata
chown -R www-data:www-data /var/www/moodledata
chmod -R 777 /var/www/moodledata
chmod -R 755 /var/www/moodle

# Change the Apache DocumentRoot using sed so Moodle opens at http://$DOMAIN
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/moodle.conf
sed -i 's|/var/www/html|/var/www/moodle|g' /etc/apache2/sites-available/moodle.conf
a2dissite 000-default.conf
a2ensite moodle.conf
systemctl reload apache2

# Update the php.ini files, required to pass Moodle install check
sed -i 's/.*max_input_vars =.*/max_input_vars = 5000/' /etc/php/8.1/apache2/php.ini
sed -i 's/.*post_max_size =.*/post_max_size = 80M/' /etc/php/8.1/apache2/php.ini
sed -i 's/.*upload_max_filesize =.*/upload_max_filesize = 80M/' /etc/php/8.1/apache2/php.ini

# Restart Apache to allow changes to take place
service apache2 restart
echo "Step 3 has completed."

# Step 4: Set up cron job to run every minute 
echo "Setting up cron job for the www-data user..."
CRON_JOB="* * * * * /var/www/moodle/admin/cli/cron.php >/dev/null"
(crontab -u www-data -l 2>/dev/null | grep -v -F "$CRON_JOB"; echo "$CRON_JOB") | crontab -u www-data -
echo "Step 4 has completed."

# Step 5: Secure the MySQL service and create the database and user for Moodle
echo "Securing MySQL service and creating the database and user for Moodle..."
# Set the root password using mysqladmin
mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"

# Create the Moodle database and user
echo "Creating the Moodle database and user..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodleuser'@'localhost' IDENTIFIED BY '$MYSQL_MOODLEUSER_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "SQL root password: $MYSQL_ROOT_PASSWORD"
echo "Moodle SQL password: $MYSQL_MOODLEUSER_PASSWORD"

# Final permissions
chmod -R 777 /var/www/moodle
echo "Step 5 has completed."

# Step 6: Create config.php file for Moodle
echo "Creating config.php for Moodle..."
cat <<EOF > /var/www/moodle/config.php
<?php  // Moodle configuration file

unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mariadb';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = 'localhost';
\$CFG->dbname    = 'moodle';
\$CFG->dbuser    = 'moodleuser';
\$CFG->dbpass    = '$MYSQL_MOODLEUSER_PASSWORD';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array (
  'dbpersist' => false,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

\$CFG->wwwroot   = 'http://$DOMAIN';
\$CFG->dataroot  = '/var/www/moodledata';
\$CFG->admin     = 'admin';

\$CFG->directorypermissions = 02777;

require_once(__DIR__ . '/lib/setup.php');

// No closing tag in config.php
EOF
echo "config.php has been created."

# Step 7: Install Certbot and configure HTTPS
echo "Installing Certbot and configuring HTTPS..."
apt-get install -y certbot python3-certbot-apache
certbot --apache -d $DOMAIN

echo "Moodle installation and setup completed successfully."

# Afficher les mots de passe pertinents
echo "MySQL root password: $MYSQL_ROOT_PASSWORD"
echo "Moodle MySQL user password: $MYSQL_MOODLEUSER_PASSWORD"
