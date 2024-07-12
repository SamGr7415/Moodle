#!/bin/bash

# Function to generate a random password
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 20
}

# Generate random passwords
MARIADB_ROOT_PASSWORD=$(generate_password)
MOODLE_DB_PASSWORD=$(generate_password)

# Update the package list and upgrade the packages
apt update
apt upgrade -y

# Install necessary packages
apt install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-xml php-curl php-zip php-gd php-intl php-mbstring git

# Start MariaDB service
systemctl start mariadb

# Secure MariaDB installation and set the root password
mysql --user=root <<_EOF_
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
  FLUSH PRIVILEGES;
_EOF_

# Define Moodle version and directories
MOODLE_VERSION=MOODLE_404_STABLE
MOODLE_DIR=/var/www/html/moodle
MOODLEDATA_DIR=/var/moodledata

# Download MOODLE_404_STABLE
if [ ! -d "/var/www/html" ]; then
  mkdir -p /var/www/html
fi
cd /var/www/html
if [ ! -d "$MOODLE_DIR" ]; then
  git clone git://git.moodle.org/moodle.git moodle
  cd moodle
  git checkout -b $MOODLE_VERSION origin/$MOODLE_VERSION
else
  echo "Moodle directory already exists. Skipping clone."
fi

# Create Moodle data directory
if [ ! -d "$MOODLEDATA_DIR" ]; then
  mkdir /var/moodledata
  chown -R www-data:www-data /var/moodledata
else
  echo "Moodle data directory already exists."
fi

# Set correct permissions
chown -R www-data:www-data $MOODLE_DIR
chmod -R 755 $MOODLE_DIR

# Create the database and user for Moodle
mysql --user=root --password=$MARIADB_ROOT_PASSWORD <<_EOF_
  CREATE DATABASE IF NOT EXISTS moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER IF NOT EXISTS 'moodleuser'@'localhost' IDENTIFIED BY '${MOODLE_DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
  FLUSH PRIVILEGES;
_EOF_

# Save passwords to a secure file
PASSWORD_FILE=/root/mariadb_passwords.txt
echo "MariaDB root password: ${MARIADB_ROOT_PASSWORD}" > $PASSWORD_FILE
echo "Moodle database user 'moodleuser' password: ${MOODLE_DB_PASSWORD}" >> $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Create a virtual host for Moodle
if [ ! -f "/etc/apache2/sites-available/moodle.conf" ]; then
  cat <<EOF > /etc/apache2/sites-available/moodle.conf
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/moodle
    <Directory /var/www/html/moodle>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
else
  echo "Moodle virtual host configuration already exists."
fi

# Enable the Moodle site and rewrite module
a2ensite moodle.conf
a2enmod rewrite

# Restart Apache to apply changes
systemctl restart apache2

# Install Certbot using APT
apt install -y certbot python3-certbot-apache

# Obtain the SSL certificate for the domain
certbot --apache -d academicefrei.site --non-interactive --agree-tos -m your-email@academicefrei.site

# Set up automatic renewal
echo "0 0,12 * * * root certbot renew --quiet" > /etc/cron.d/certbot-renew

# Restart Apache to apply changes
systemctl restart apache2

# Display the generated passwords
echo "Installation script completed."
echo "MariaDB root password: ${MARIADB_ROOT_PASSWORD}"
echo "Moodle database user 'moodleuser' password: ${MOODLE_DB_PASSWORD}"
echo "Passwords have been saved to ${PASSWORD_FILE}."
echo "Please open your browser and navigate to http://academicefrei.site to complete the installation through the web interface."

# Verify and display MariaDB users
mysql --user=root --password=$MARIADB_ROOT_PASSWORD <<_EOF_
  SELECT User, Host FROM mysql.user;
  SHOW GRANTS FOR 'moodleuser'@'localhost';
_EOF_
