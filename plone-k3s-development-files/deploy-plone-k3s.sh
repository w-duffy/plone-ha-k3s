#!/bin/bash

echo "Deploying Plone CMS on k3s..."
echo "Note: This script requires sudo access for k3s kubectl"
echo ""

# Function to run k3s kubectl
k3s_kubectl() {
    sudo k3s kubectl "$@"
}

# Apply all manifests in order
echo "Creating namespace..."
k3s_kubectl apply -f plone-namespace.yaml

echo "Deploying PostgreSQL..."
k3s_kubectl apply -f plone-postgres.yaml

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
k3s_kubectl wait --for=condition=ready pod -l app=postgres -n plone --timeout=120s || echo "PostgreSQL is taking longer to start..."

echo "Deploying Plone backend..."
k3s_kubectl apply -f plone-backend.yaml

echo "Deploying Plone frontend..."
k3s_kubectl apply -f plone-frontend.yaml

echo "Creating Nginx configuration..."
k3s_kubectl apply -f plone-nginx-config.yaml

echo "Deploying Nginx reverse proxy..."
k3s_kubectl apply -f plone-nginx.yaml

echo ""
echo "Deployment initiated! Checking status..."
echo ""
k3s_kubectl get pods -n plone
echo ""
echo "Plone will be accessible at: http://localhost:30080"
echo ""
echo "Commands for monitoring:"
echo "  sudo k3s kubectl get pods -n plone"
echo "  sudo k3s kubectl logs -f deployment/plone-backend -n plone"
echo "  sudo k3s kubectl logs -f deployment/plone-frontend -n plone"