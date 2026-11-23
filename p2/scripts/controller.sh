#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "==> Mise à jour des paquets..."
apt-get update -y

echo "==> Installation des dépendances..."
apt-get install -y curl ca-certificates 


echo "==> Copie du fichier config.yaml..."
mkdir -p /etc/rancher/k3s
cp /vagrant/config/controller.yaml /etc/rancher/k3s/config.yaml
chmod 600 /etc/rancher/k3s/config.yaml

echo "==> Installation de K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl

echo "==> Attente du démarrage de K3s..."
for _ in $(seq 1 60); do
  if [ -f /etc/rancher/k3s/k3s.yaml ] && kubectl get nodes >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "ERREUR: K3s n'est pas prêt après 2 minutes"
  systemctl status k3s --no-pager || true
  journalctl -u k3s -n 80 --no-pager || true
  exit 1
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
printf '\nexport KUBECONFIG=/etc/rancher/k3s/k3s.yaml\n' >> /home/vagrant/.bashrc
printf '\nexport KUBECONFIG=/etc/rancher/k3s/k3s.yaml\n' >> /root/.bashrc

echo "==> Vérification des nœuds..."
kubectl get nodes -o wide

echo "==> K3s installé avec succès !"

echo "==> Lancement de l'app 1 deployement et services ..."
kubectl create configmap app1-index --from-file=/vagrant/config/app1/index.html --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f /vagrant/config/app1/deployement.yaml
kubectl apply -f /vagrant/config/app1/service.yaml

echo "==> Lancement de l'app 2 deployement et services ..."
kubectl create configmap app2-index --from-file=/vagrant/config/app2/index.html --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f /vagrant/config/app2/deployement.yaml
kubectl apply -f /vagrant/config/app2/service.yaml

echo "==> Lancement de l'app 3 deployement et services ..."
kubectl create configmap app3-index --from-file=/vagrant/config/app3/index.html --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f /vagrant/config/app3/deployement.yaml
kubectl apply -f /vagrant/config/app3/service.yaml

echo "==> Lancement de l'Ingress ..."
kubectl apply -f /vagrant/config/ingress.yaml
kubectl get ingress app-ingress -o wide

echo "==> Vérification des ressources déployées..."
kubectl get all -o wide

echo "==> Déploiement terminé !"
