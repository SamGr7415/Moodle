#!/bin/bash

# Ajouter manuellement le PPA d'ondrej/php
echo "Adding ondrej/php PPA..."
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main" > /etc/apt/sources.list.d/ondrej-php.list
echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu focal main" >> /etc/apt/sources.list.d/ondrej-php.list

# Ajouter la clé GPG pour le PPA
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C

# Mettre à jour les paquets
apt-get update

echo "PPA ondrej/php ajouté avec succès."
