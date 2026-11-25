#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/configs/application.yaml"
ARGO_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

if [ ! -f "${APP_MANIFEST}" ]; then
    echo "ERREUR: fichier introuvable: ${APP_MANIFEST}"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1 || ! command -v k3d >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1; then
    echo "ERREUR: docker/k3d/kubectl manquants. Lance d'abord scripts/install.sh"
    exit 1
fi

echo "==> Création du cluster K3d (si absent)"
if ! k3d cluster list iot >/dev/null 2>&1; then
    k3d cluster create iot -p "8888:8888@loadbalancer"
else
    echo "Cluster iot déjà présent"
fi

echo "==> Création des namespaces argocd et dev"
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd
kubectl get namespace dev >/dev/null 2>&1 || kubectl create namespace dev

echo "==> Installation d'ArgoCD"
if kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    echo "ArgoCD déjà installé, étape d'installation ignorée"
else
    kubectl create -n argocd -f "${ARGO_INSTALL_URL}" >/tmp/argocd-install.log
    echo "Manifeste ArgoCD créé (log: /tmp/argocd-install.log)"
fi

echo "==> Attente du démarrage d'ArgoCD (peut prendre plusieurs minutes)..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=600s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=600s
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=600s

echo "==> Configuration de l'application ArgoCD"
kubectl apply -f "${APP_MANIFEST}"

echo "==> Mot de passe initial ArgoCD (utilisateur : admin) :"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "==> Déploiement terminé avec succès !"
