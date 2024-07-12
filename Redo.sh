#!/bin/bash

# Étape 1 : Installer les dépendances nécessaires
apt-get update
apt-get install -y lsb-release apt-transport-https ca-certificates

# Étape 2 : Ajouter le dépôt ondrej/php
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list

# Étape 3 : Ajouter la clé GPG pour le dépôt
wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -

# Étape 4 : Mettre à jour les paquets et installer PHP 7.4
apt-get update
apt-get install -y php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-common php7.4-cli

echo "PHP 7.4 et les modules nécessaires ont été installés avec succès."
