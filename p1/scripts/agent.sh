#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "==> Mise à jour des paquets..."
apt-get update -y

echo "==> Installation des dépendances..."
apt-get install -y curl ca-certificates


echo "==> [Agent] Récupération du token pour l'agent..."
# Boucle de sécurité : on attend que le jeton soit présent ET non vide
TRY=0
while [ ! -s /vagrant/node-token ]; do
    if [ $TRY -ge 12 ]; then
        echo "==> [Agent] Le token n'est pas disponible après 1 minute, abandon."
        exit 1
    fi
    echo "==> [Agent] Le token n'est pas encore prêt, attente de 5 secondes... Essai $((TRY+1))/12"
    sleep 5
    TRY=$((TRY+1))
done

# Nettoyage des caractères invisibles de retour à la ligne
TOKEN=$(tr -d '\r\n' < /vagrant/node-token)
if [ -z "$TOKEN" ]; then
    echo "==> [Agent] Le token est vide après nettoyage, abandon."
    exit 1
fi
echo "==> [Agent] Token récupéré avec succès."

echo "==> [Agent] Preparation du fichier config.yaml pour l'agent..."
mkdir -p /etc/rancher/k3s
cp /vagrant/config/agent.yaml /etc/rancher/k3s/config.yaml
echo "==> [Agent] Ajout du token au fichier de configuration..."
# Remplacement du placeholder {K3S_TOKEN} (ou ${K3S_TOKEN}) par le token réel
ESCAPED_TOKEN=${TOKEN//&/\\&}
ESCAPED_TOKEN=${ESCAPED_TOKEN//#/\\#}
sed -e "s#{K3S_TOKEN}#${ESCAPED_TOKEN}#g" \
    -e "s#\${K3S_TOKEN}#${ESCAPED_TOKEN}#g" \
    /vagrant/config/agent.yaml > /etc/rancher/k3s/config.yaml
echo "" >> /etc/rancher/k3s/config.yaml # Ajout d'une ligne vide à la fin du fichier pour éviter les problèmes de format YAML
chmod 600 /etc/rancher/k3s/config.yaml

echo "==> [Agent] Attente que l'API server réponde..."
API_TIMEOUT=180
API_ELAPSED=0
until curl -sk --max-time 5 https://192.168.56.110:6443/cacerts >/dev/null; do
    if [ $API_ELAPSED -ge $API_TIMEOUT ]; then
        echo "==> [Agent] Timeout: API server inaccessible après ${API_TIMEOUT}s (endpoint /cacerts)."
        exit 1
    fi
    sleep 3
    API_ELAPSED=$((API_ELAPSED + 3))
done

echo "==> [Agent] Installation de K3s Agent..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -

for _ in $(seq 1 30); do
    if systemctl is-active --quiet k3s-agent; then
        break
    fi
    sleep 2
done

if ! systemctl is-active --quiet k3s-agent; then
    echo "==> [Agent] k3s-agent n'est pas actif, logs :"
    journalctl -u k3s-agent -n 60 --no-pager
    exit 1
fi



echo "==> [Agent] Création du lien symbolique pour kubectl..."
ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl

echo "==> [Agent] K3s Agent est connecté et prêt !"
