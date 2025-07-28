#!/bin/bash

echo "=== Plone on k3s Status ==="
echo ""
echo "Pods in plone namespace:"
sudo k3s kubectl get pods -n plone -o wide
echo ""
echo "Services in plone namespace:"
sudo k3s kubectl get services -n plone
echo ""
echo "To check if Plone is ready, look for all pods showing 'Running' status."
echo "Access Plone at: http://localhost:30080"
echo ""
echo "Useful commands:"
echo "  View backend logs: sudo k3s kubectl logs -f deployment/plone-backend -n plone"
echo "  View frontend logs: sudo k3s kubectl logs -f deployment/plone-frontend -n plone"
echo "  Scale backend: sudo k3s kubectl scale deployment plone-backend -n plone --replicas=2"
echo "  Delete everything: sudo k3s kubectl delete namespace plone"