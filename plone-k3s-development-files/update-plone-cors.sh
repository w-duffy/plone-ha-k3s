#!/bin/bash

echo "=== Updating Plone deployment to fix CORS issues ==="
echo ""

# Apply updated configurations
echo "1. Updating frontend configuration with API paths..."
sudo k3s kubectl apply -f plone-frontend.yaml

echo ""
echo "2. Updating nginx configuration with CORS headers..."
sudo k3s kubectl apply -f plone-nginx-config.yaml

echo ""
echo "3. Restarting pods to apply changes..."
sudo k3s kubectl rollout restart deployment/plone-frontend -n plone
sudo k3s kubectl rollout restart deployment/nginx -n plone

echo ""
echo "4. Waiting for rollout to complete..."
sudo k3s kubectl rollout status deployment/plone-frontend -n plone
sudo k3s kubectl rollout status deployment/nginx -n plone

echo ""
echo "5. Current pod status:"
sudo k3s kubectl get pods -n plone

echo ""
echo "Updates applied! Plone should now be accessible at:"
echo "  http://localhost:30080"
echo ""
echo "The frontend will now correctly use the API through the nginx proxy."