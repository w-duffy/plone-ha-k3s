#!/bin/bash

# Status check script for Plone k3s deployment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Load configuration
CONFIG_FILE="$BASE_DIR/config/deployment.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

echo -e "${BLUE}=== Plone k3s Deployment Status ===${NC}"
echo ""

# Check if k3s is running
echo -n "k3s status: "
if pgrep -f "k3s server" > /dev/null; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Not running${NC}"
    echo "Start k3s with: sudo k3s server &"
    exit 1
fi

echo ""
echo "Pod Status:"
echo "─────────────────────────────────────────"
sudo k3s kubectl get pods -n plone -o wide

echo ""
echo "Service Status:"
echo "─────────────────────────────────────────"
sudo k3s kubectl get services -n plone

# Get node IP
NODE_IP=$(sudo k3s kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "Access URLs:"
echo "─────────────────────────────────────────"
echo -e "  Local:        ${GREEN}http://localhost:${PLONE_PORT}${NC}"
echo -e "  Node IP:      ${GREEN}http://${NODE_IP}:${PLONE_PORT}${NC}"
if [ "$PLONE_HOST" != "localhost" ]; then
    echo -e "  Configured:   ${GREEN}http://${PLONE_HOST}:${PLONE_PORT}${NC}"
fi

# Test connectivity
echo ""
echo "Testing connectivity:"
echo -n "  API endpoint: "
if curl -s -f "http://${NODE_IP}:${PLONE_PORT}/++api++/" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

echo -n "  Frontend: "
if curl -s -f "http://${NODE_IP}:${PLONE_PORT}/" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Check for common issues
echo ""
POSTGRES_POD=$(sudo k3s kubectl get pods -n plone -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
BACKEND_POD=$(sudo k3s kubectl get pods -n plone -l app=plone-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
FRONTEND_POD=$(sudo k3s kubectl get pods -n plone -l app=plone-frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ ! -z "$POSTGRES_POD" ]; then
    STATUS=$(sudo k3s kubectl get pod $POSTGRES_POD -n plone -o jsonpath='{.status.phase}')
    if [ "$STATUS" != "Running" ]; then
        echo -e "${YELLOW}⚠ PostgreSQL not ready. Check logs:${NC}"
        echo "  sudo k3s kubectl logs $POSTGRES_POD -n plone"
    fi
fi

if [ ! -z "$BACKEND_POD" ]; then
    STATUS=$(sudo k3s kubectl get pod $BACKEND_POD -n plone -o jsonpath='{.status.phase}')
    if [ "$STATUS" != "Running" ]; then
        echo -e "${YELLOW}⚠ Backend not ready. Check logs:${NC}"
        echo "  sudo k3s kubectl logs $BACKEND_POD -n plone"
    fi
fi

echo ""
echo "Useful commands:"
echo "  View logs:    sudo k3s kubectl logs -f deployment/[name] -n plone"
echo "  Port forward: sudo k3s kubectl port-forward -n plone service/nginx 8080:80"