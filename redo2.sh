#!/bin/bash

# Mettre à jour le système et installer les dépendances nécessaires
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Ajouter la clé GPG officielle de sury.org pour PHP
curl -fsSL https://packages.sury.org/php/apt.gpg | apt-key add -

# Ajouter le dépôt sury.org pour PHP
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list

# Mettre à jour les paquets
apt-get update

# Installer PHP 7.4 et les modules nécessaires
apt-get install -y php7.4 libapache2-mod-php7.4 php7.4-common php7.4-cli php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-intl php7.4-soap php7.4-zip php7.4-mbstring php7.4-pspell php7.4-json

# Redémarrer Apache pour appliquer les modifications
systemctl restart apache2

echo "PHP 7.4 et les modules nécessaires ont été installés avec succès."
