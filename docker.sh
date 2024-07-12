#!/bin/bash

# Mettre à jour le système et installer les dépendances nécessaires
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Ajouter la clé GPG officielle de Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Ajouter le dépôt Docker
echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

# Mettre à jour le système et installer Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Tirer l'image Docker officielle de Moodle
docker pull moodle

# Exécuter Moodle dans un conteneur Docker
docker run --name moodle -d -p 80:80 -p 443:443 moodle

echo "Docker et Moodle ont été installés et exécutés avec succès. Accédez à Moodle via http://your_server_ip"
