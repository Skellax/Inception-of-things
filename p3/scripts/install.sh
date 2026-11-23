#!/bin/bash

set -e # Arrête le script immédiatement en cas d'erreur

# Mise à jour et installation des paquets de base
echo "==> Installation des paquets nécessaires"
apt-get update
apt-get install -y \
    curl \
    git \
    ca-certificates \
    apt-transport-https

# Installation de Docker
echo "==> Installation de Docker"
apt-get remove -y docker docker-engine docker.io containerd runc || true
apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin -y || true
rm -rf /etc/bash_completion.d/docker /usr/local/bin/docker-compose /etc/bash_completion.d/docker
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Ajout de l'utilisateur courant au groupe docker (si exécuté avec sudo)
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
fi

echo "==> Vérification de Docker"
docker --version

# Installation de K3d
echo "==> Installation de K3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
echo "==> Vérification de K3d"
k3d --version

# Installation de kubectl
echo "==> Installation de kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl
echo "==> Vérification de kubectl"
kubectl version --client

# Installation d'ArgoCD CLI
echo "==> Installation de l'ArgoCD CLI"
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
install -o root -g root -m 0755 argocd /usr/local/bin/argocd
rm -f argocd
echo "==> Vérification de l'ArgoCD CLI"
argocd version --client

echo "==> Installation terminée avec succès !"
