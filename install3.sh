#!/bin/bash

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
  MYSQL_ROOT_PASSWORD="your_mysql_root_password"  # Assurez-vous d'utiliser le bon mot de passe root
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
DROP DATABASE IF EXISTS moodle;
DROP USER IF EXISTS 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EOF

  # Suppression du cron job
  crontab -u www-data -l | grep -v "/var/www/moodle/admin/cli/cron.php" | crontab -u www-data -

  echo "Cleaning completed."
}

# Exécuter le nettoyage préalable
clean_installation

# Step 1: LAMP server installation
echo "Updating system and installing required packages..."
apt-get update
apt-get install -y apache2 php7.4 libapache2-mod-php7.4 php7.4-mysql graphviz aspell git 
apt-get install -y clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql ghostscript
apt-get install -y php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring
apt-get install -y mariadb-server mariadb-client
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
chown -R www-data /var/www/moodledata
chmod -R 777 /var/www/moodledata
chmod -R 755 /var/www/moodle

# Change the Apache DocumentRoot using sed so Moodle opens at http://webaddress
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/moodle.conf
sed -i 's|/var/www/html|/var/www/moodle|g' /etc/apache2/sites-available/moodle.conf
a2dissite 000-default.conf
a2ensite moodle.conf
systemctl reload apache2

# Update the php.ini files, required to pass Moodle install check
sed -i 's/.*max_input_vars =.*/max_input_vars = 5000/' /etc/php/7.4/apache2/php.ini
sed -i 's/.*post_max_size =.*/post_max_size = 80M/' /etc/php/7.4/apache2/php.ini
sed -i 's/.*upload_max_filesize =.*/upload_max_filesize = 80M/' /etc/php/7.4/apache2/php.ini

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
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
MYSQL_MOODLEUSER_PASSWORD=$(openssl rand -base64 12)

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

# Display the generated passwords (if needed, for reference)
echo "SQL root password: $MYSQL_ROOT_PASSWORD, moodle SQL password: $MYSQL_MOODLEUSER_PASSWORD"

# Final permissions
chmod -R 777 /var/www/moodle
echo "Step 5 has completed."

echo "Moodle installation and setup completed successfully."
