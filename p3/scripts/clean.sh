#!/bin/bash

set -euo pipefail

echo "==> Nettoyage P3 en cours..."

if command -v k3d >/dev/null 2>&1; then
    if k3d cluster list iot >/dev/null 2>&1; then
        echo "==> Suppression du cluster k3d iot"
        k3d cluster delete iot
    else
        echo "==> Cluster iot déjà absent"
    fi
fi

echo "==> Suppression des namespaces ArgoCD et dev"
kubectl delete namespace argo-cd dev --ignore-not-found


echo "==> Nettoyage terminé."
