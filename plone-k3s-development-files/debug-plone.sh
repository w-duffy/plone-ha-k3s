#!/bin/bash

echo "=== Debugging Plone Deployment ==="
echo ""

echo "1. Checking all pods status:"
sudo k3s kubectl get pods -n plone -o wide
echo ""

echo "2. Checking services:"
sudo k3s kubectl get services -n plone
echo ""

echo "3. Checking nginx logs:"
sudo k3s kubectl logs -n plone -l app=nginx --tail=20
echo ""

echo "4. Checking if nginx config is loaded:"
sudo k3s kubectl describe configmap nginx-config -n plone | grep -A 20 "Data"
echo ""

echo "5. Testing internal connectivity to backend:"
NGINX_POD=$(sudo k3s kubectl get pods -n plone -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo "Testing backend connection from nginx pod..."
sudo k3s kubectl exec -n plone $NGINX_POD -- wget -O- http://backend:8080 2>&1 | head -20
echo ""

echo "6. Testing internal connectivity to frontend:"
echo "Testing frontend connection from nginx pod..."
sudo k3s kubectl exec -n plone $NGINX_POD -- wget -O- http://frontend:3000 2>&1 | head -20
echo ""

echo "7. Checking nginx service endpoints:"
sudo k3s kubectl get endpoints nginx -n plone
echo ""

echo "8. Port forwarding test (as alternative access method):"
echo "Try running this in another terminal:"
echo "  sudo k3s kubectl port-forward -n plone service/nginx 8080:80"
echo "Then access: http://localhost:8080"