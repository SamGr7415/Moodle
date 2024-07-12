#!/bin/bash

# Mise à jour des paquets et installation des dépendances nécessaires
apt update
apt install -y software-properties-common

# Ajout du PPA pour PHP 8.0
add-apt-repository -y ppa:ondrej/php
apt update

# Installation de PHP 8.0 et des extensions nécessaires
apt install -y php8.0 php8.0-cli php8.0-common php8.0-mysql php8.0-xml php8.0-mbstring php8.0-curl php8.0-gd php8.0-zip php8.0-soap php8.0-intl php8.0-readline php8.0-opcache php8.0-json php8.0-tokenizer php8.0-ctype php8.0-iconv php8.0-simplexml php8.0-spl php8.0-pcre php8.0-dom php8.0-xmlreader php8.0-hash php8.0-fileinfo php8.0-sodium php8.0-exif php8.0-zlib

# Vérification de la version de PHP installée
php -v

# Redémarrage du serveur web pour prendre en compte les modifications (si vous utilisez Apache ou Nginx)
# Pour Apache
systemctl restart apache2

# Pour Nginx (si PHP-FPM est utilisé)
systemctl restart php8.0-fpm
systemctl restart nginx

echo "Installation de PHP 8.0 et de ses extensions terminée avec succès."
