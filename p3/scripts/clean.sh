#!/bin/bash

set -euo pipefail

echo "==> Nettoyage P3 en cours..."

if command -v kubectl >/dev/null 2>&1; then
    if kubectl get namespace argo-cd >/dev/null 2>&1; then
        echo "==> Suppression de l'application Argo CD (si présente)"
        kubectl delete application wil-playground -n argo-cd --ignore-not-found --wait=true
    fi

    echo "==> Suppression des namespaces dev et argo-cd (si présents)"
    kubectl delete namespace dev --ignore-not-found --wait=true
    kubectl delete namespace argo-cd --ignore-not-found --wait=true
fi

if command -v k3d >/dev/null 2>&1; then
    if k3d cluster list iot >/dev/null 2>&1; then
        echo "==> Suppression du cluster k3d iot"
        k3d cluster delete iot
    else
        echo "==> Cluster iot déjà absent"
    fi
fi

echo "==> Nettoyage terminé."
