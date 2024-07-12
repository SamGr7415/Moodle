#!/bin/bash

# Generate a complex password
DB_PASS=$(openssl rand -base64 16)
DB_USER="moodleuser"

# Variables
DB_NAME="moodle"
DOMAIN="thebestdeal.icu"
MOODLE_PATH="/var/www/html/moodle"
MOODLE_DATA="/var/www/html/moodledata"
CREDENTIALS_FILE="/root/moodle_db_credentials.txt"

# Function to handle errors
handle_error() {
    echo "Error on line $1"
    exit 1
}
trap 'handle_error $LINENO' ERR

# Update and upgrade system packages
apt update && apt upgrade -y

# Install Apache, MariaDB, PHP and required PHP extensions
apt install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-xml php-intl php-curl php-zip php-gd php-soap php-mbstring wget unzip

# Secure MariaDB
mysql_secure_installation <<EOF

y
$DB_PASS
$DB_PASS
y
y
y
y
EOF

# Create Moodle database and user
mysql -u root -p$DB_PASS <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Store credentials in a file
echo "Database User: $DB_USER" > $CREDENTIALS_FILE
echo "Database Password: $DB_PASS" >> $CREDENTIALS_FILE
chmod 600 $CREDENTIALS_FILE

# Create /var/www/html if it doesn't exist
if [ ! -d /var/www/html ]; then
    mkdir -p /var/www/html
fi

# Download and install Moodle
cd /var/www/html
rm -rf $MOODLE_PATH
rm -rf $MOODLE_DATA
wget https://download.moodle.org/download.php/stable400/moodle-latest-400.zip -O moodle.zip
unzip moodle.zip
mv moodle $MOODLE_PATH
mkdir $MOODLE_DATA

# Set correct permissions
chown -R www-data:www-data $MOODLE_PATH
chown -R www-data:www-data $MOODLE_DATA
chmod -R 755 $MOODLE_PATH
chmod -R 777 $MOODLE_DATA

# Configure Apache
cat > /etc/apache2/sites-available/moodle.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@$DOMAIN
    DocumentRoot $MOODLE_PATH
    ServerName $DOMAIN

    <Directory $MOODLE_PATH>
        AllowOverride All
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/moodle_error.log
    CustomLog \${APACHE_LOG_DIR}/moodle_access.log combined
</VirtualHost>
EOF

# Enable the Moodle site and necessary modules
a2ensite moodle.conf
a2enmod rewrite
systemctl restart apache2

# Configure UFW Firewall
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Install Certbot and obtain SSL certificate
apt install -y certbot python3-certbot-apache
certbot --apache -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# Finalize Moodle Installation via CLI
sudo -u www-data /usr/bin/php $MOODLE_PATH/admin/cli/install.php --wwwroot=https://$DOMAIN --dataroot=$MOODLE_DATA --dbtype=mysqli --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --fullname="Moodle Site" --shortname="Moodle" --adminuser=admin --adminpass=Admin@12345 --adminemail=admin@$DOMAIN --non-interactive --agree-license

# Set up Cron for Moodle
echo '* * * * * www-data /usr/bin/php $MOODLE_PATH/admin/cli/cron.php >/dev/null' > /etc/cron.d/moodle

echo "Moodle installation completed successfully on $DOMAIN"
echo "Database credentials stored in $CREDENTIALS_FILE"
