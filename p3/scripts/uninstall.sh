#!/bin/bash

set -e

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Erreur: lance ce script avec sudo."
    exit 1
fi

KEEP_DOCKER=${KEEP_DOCKER:-false}

echo "==> Suppression du cluster K3d"
if command -v k3d >/dev/null 2>&1; then
    k3d cluster delete iot 2>/dev/null || true
    rm -f /usr/local/bin/k3d
fi

echo "==> Suppression de kubectl et Argo CD CLI"
rm -f /usr/local/bin/kubectl
rm -f /usr/local/bin/argocd

if [ "$KEEP_DOCKER" != "true" ]; then
    echo "==> Arrêt et suppression de Docker"
    systemctl disable --now docker 2>/dev/null || true
    apt-get remove -y docker.io docker-compose 2>/dev/null || true
    apt-get autoremove -y
else
    echo "==> Docker conservé"
fi

echo "==> Désinstallation terminée"
echo "Déconnecte-toi puis reconnecte-toi si l'utilisateur appartenait au groupe docker."
