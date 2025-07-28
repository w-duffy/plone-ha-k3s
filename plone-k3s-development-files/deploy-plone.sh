#!/bin/bash

echo "Deploying Plone CMS on k3s..."

# Apply all manifests in order
kubectl apply -f plone-namespace.yaml
echo "Namespace created."

kubectl apply -f plone-postgres.yaml
echo "PostgreSQL deployed."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n plone --timeout=60s

kubectl apply -f plone-backend.yaml
echo "Plone backend deployed."

kubectl apply -f plone-frontend.yaml
echo "Plone frontend deployed."

kubectl apply -f plone-nginx-config.yaml
echo "Nginx configuration created."

kubectl apply -f plone-nginx.yaml
echo "Nginx reverse proxy deployed."

echo ""
echo "Deployment complete! Plone will be accessible at:"
echo "http://localhost:30080"
echo ""
echo "It may take a few minutes for all services to start up."
echo "You can check the status with: kubectl get pods -n plone"