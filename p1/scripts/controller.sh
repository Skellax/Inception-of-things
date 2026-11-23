#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "==> Mise à jour des paquets..."
apt-get update -y


echo "==> Installation des dépendances..."
apt-get install -y curl ca-certificates

echo "==> [Controller] Copie du fichier config.yaml..."
mkdir -p /etc/rancher/k3s
cp /vagrant/config/controller.yaml /etc/rancher/k3s/config.yaml
chmod 600 /etc/rancher/k3s/config.yaml

echo "==> [Controller] Installation de K3s Server..."
# Correction de la syntaxe curl ici pour bien télécharger le script
curl -sfL https://get.k3s.io -o k3s-install.sh
sh k3s-install.sh

echo "==> [Controller] K3s Server est installé !"

echo "==> [Controller] Attente de 5 secondes pour la stabilité..."
sleep 5

echo "==> [Controller] Vérification si k3s est bien démarré..."
systemctl status k3s --no-pager
if systemctl is-active --quiet k3s; then
    echo "==> [Controller] K3s est en cours d'exécution."
else
    echo "==> [Controller] K3s n'est pas démarré correctement."
    exit 1
fi

echo "==> [Controller] Attente que l'API server soit réellement prêt..."
READY_TIMEOUT=240
READY_ELAPSED=0
until k3s kubectl get --raw='/readyz' 2>/dev/null | grep -q "ok"; do
    if [ $READY_ELAPSED -ge $READY_TIMEOUT ]; then
        echo "==> [Controller] Timeout: API server non prêt après ${READY_TIMEOUT}s."
        journalctl -u k3s -n 80 --no-pager
        exit 1
    fi
    sleep 3
    READY_ELAPSED=$((READY_ELAPSED + 3))
done



echo "==> [Controller] Sauvegarde du token pour l'agent..."
while [ ! -s /var/lib/rancher/k3s/server/node-token ]; do
    sleep 2
done
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

echo "==> [Controller] K3s Server est prêt !"
