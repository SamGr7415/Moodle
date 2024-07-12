#!/bin/bash

# Étape 1 : Ajouter les backports de Debian
echo "Adding Debian backports..."
echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" > /etc/apt/sources.list.d/backports.list

# Mettre à jour les paquets
apt-get update

# Étape 2 : Installer PHP 7.4 depuis les backports
echo "Installing PHP 7.4 and necessary modules from backports..."
apt-get -t $(lsb_release -sc)-backports install -y php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-common php7.4-cli

echo "PHP 7.4 et les modules nécessaires ont été installés avec succès."
