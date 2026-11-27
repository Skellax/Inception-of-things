#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/configs/application.yaml"
K3D_CONFIG="${ROOT_DIR}/configs/k3d-config.yaml"
ARGO_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ARGO_NS="argocd"

if [ ! -f "${APP_MANIFEST}" ] || [ ! -f "${K3D_CONFIG}" ]; then
    echo "ERREUR: fichier application.yaml ou k3d-config.yaml introuvable"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1 || ! command -v k3d >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1; then
    echo "ERREUR: docker/k3d/kubectl manquants. Lance d'abord scripts/install.sh"
    exit 1
fi

echo "==> Création du cluster K3d (si absent)"
if ! k3d cluster get iot >/dev/null 2>&1; then
    k3d cluster create --config "${K3D_CONFIG}"
else
    echo "Cluster iot déjà présent"
fi

echo "==> Attente de la disponibilité de l'API Kubernetes..."
k3d kubeconfig merge iot --kubeconfig-switch-context >/dev/null

echo "==> Attente de l'API Kubernetes..."
kubectl wait --for=condition=Ready node --all --timeout=180s >/dev/null

echo "==> Création des namespaces ${ARGO_NS} et dev"
kubectl get namespace "${ARGO_NS}" >/dev/null 2>&1 || kubectl create namespace "${ARGO_NS}"
kubectl get namespace dev >/dev/null 2>&1 || kubectl create namespace dev

echo "==> Installation d'ArgoCD"
if kubectl get deployment argocd-server -n "${ARGO_NS}" >/dev/null 2>&1; then
    echo "ArgoCD déjà installé, étape d'installation ignorée"
else
    kubectl create -n "${ARGO_NS}" -f "${ARGO_INSTALL_URL}" >/tmp/argocd-install.log
fi

echo "==> Attente du démarrage d'ArgoCD (peut prendre plusieurs minutes)..."
kubectl rollout status deployment/argocd-server -n "${ARGO_NS}" --timeout=600s

echo "==> Configuration de l'application ArgoCD"
kubectl apply -n "${ARGO_NS}" -f "${APP_MANIFEST}"

echo "==> Mot de passe initial ArgoCD (utilisateur : admin) :"
kubectl get secret argocd-initial-admin-secret -n "${ARGO_NS}" -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "==> Déploiement terminé avec succès !"