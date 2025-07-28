#!/bin/bash

echo "=== Testing Plone k3s Deployment ==="
echo ""

# Get the node IP
NODE_IP=$(sudo k3s kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "Testing with node IP: $NODE_IP"
echo ""

echo "1. Testing main site:"
curl -s -o /dev/null -w "   Status: %{http_code}\n" http://$NODE_IP:30080
echo ""

echo "2. Testing API endpoint:"
curl -s http://$NODE_IP:30080/++api++/ | jq -r '.["@id"]' 2>/dev/null || echo "   API not responding properly"
echo ""

echo "3. Testing CORS headers:"
curl -s -I http://$NODE_IP:30080/++api++/ | grep -i "access-control" || echo "   No CORS headers found"
echo ""

echo "4. Pod status:"
sudo k3s kubectl get pods -n plone --no-headers | while read line; do
    name=$(echo $line | awk '{print $1}')
    status=$(echo $line | awk '{print $3}')
    ready=$(echo $line | awk '{print $2}')
    if [ "$status" = "Running" ]; then
        echo "   ✅ $name: $status ($ready)"
    else
        echo "   ❌ $name: $status ($ready)"
    fi
done
echo ""

echo "Access Plone at any of these URLs:"
echo "   - http://localhost:30080"
echo "   - http://$NODE_IP:30080"
echo "   - http://[your-machine-ip]:30080"