#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install kubectl to proceed."
    exit 1
fi

# Check if the user is connected to a Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "You are not connected to a Kubernetes cluster. Please configure kubectl correctly."
    exit 1
fi

# Namespace for Argo CD
NAMESPACE="argocd"

echo "Creating namespace for Argo CD..."
kubectl create namespace $NAMESPACE

echo "Installing Argo CD..."
kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD components to be ready..."
kubectl wait --namespace $NAMESPACE --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=180s

# Get the initial admin password
echo "Fetching Argo CD initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
echo "Argo CD initial admin password: $ARGOCD_PASSWORD"

# Port-forward to access Argo CD UI
echo "You can access the Argo CD UI by port-forwarding:"
echo "kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"

