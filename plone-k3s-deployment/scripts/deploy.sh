#!/bin/bash

# Plone k3s Deployment Script
# Handles both NodePort and Ingress deployment scenarios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Load configuration
CONFIG_FILE="$BASE_DIR/config/deployment.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo -e "${GREEN}Loaded configuration from $CONFIG_FILE${NC}"
else
    echo -e "${YELLOW}Warning: No configuration file found. Using defaults.${NC}"
    PLONE_HOST="localhost"
    PLONE_PORT="30080"
fi

# Parse command line arguments
USE_INGRESS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --ingress)
            USE_INGRESS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --ingress    Use Ingress instead of NodePort (for k3s with Traefik)"
            echo ""
            echo "Default: Uses NodePort (30080) for external access"
            echo "With --ingress: Uses k3s Traefik ingress on port 80"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=== Deploying Plone CMS on k3s ===${NC}"

# Check if Traefik is installed
echo -n "Checking for Traefik ingress controller... "
if sudo k3s kubectl get service -n kube-system traefik > /dev/null 2>&1; then
    echo -e "${GREEN}Found${NC}"
    if [ "$USE_INGRESS" = false ]; then
        echo -e "${BLUE}ℹ Traefik detected. Consider using --ingress flag for port 80 access${NC}"
    fi
else
    echo -e "${YELLOW}Not found${NC}"
    if [ "$USE_INGRESS" = true ]; then
        echo -e "${RED}Error: --ingress specified but Traefik not found${NC}"
        exit 1
    fi
fi

echo ""
echo "Deployment mode: $([ "$USE_INGRESS" = true ] && echo "Ingress (port 80)" || echo "NodePort (port $PLONE_PORT)")"
echo ""

# Function to apply manifest
apply_manifest() {
    local file=$1
    local name=$2
    echo -n "Deploying $name... "
    if sudo k3s kubectl apply -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        sudo k3s kubectl apply -f "$file"
        exit 1
    fi
}

# Apply core manifests
apply_manifest "$BASE_DIR/k8s/01-namespace.yaml" "namespace"
apply_manifest "$BASE_DIR/k8s/02-postgres.yaml" "PostgreSQL"

# Wait for PostgreSQL
echo -n "Waiting for PostgreSQL to be ready... "
if sudo k3s kubectl wait --for=condition=ready pod -l app=postgres -n plone --timeout=120s > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ PostgreSQL is taking longer to start${NC}"
fi

apply_manifest "$BASE_DIR/k8s/03-backend.yaml" "Plone backend"
apply_manifest "$BASE_DIR/k8s/04-frontend.yaml" "Volto frontend"

# Handle Nginx deployment based on mode
if [ "$USE_INGRESS" = true ]; then
    # Create temporary nginx manifest without NodePort
    echo -n "Configuring Nginx for Ingress mode... "
    sed '/type: NodePort/,/nodePort: 30080/d' "$BASE_DIR/k8s/05-nginx.yaml" | \
    sed 's/type: NodePort/type: ClusterIP/' > /tmp/nginx-ingress.yaml
    echo -e "${GREEN}✓${NC}"
    
    apply_manifest "/tmp/nginx-ingress.yaml" "Nginx (ClusterIP)"
    apply_manifest "$BASE_DIR/k8s/06-ingress-optional.yaml" "Ingress"
    
    # Cleanup
    rm -f /tmp/nginx-ingress.yaml
else
    apply_manifest "$BASE_DIR/k8s/05-nginx.yaml" "Nginx (NodePort)"
fi

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
echo ""

# Wait a moment for pods to start
sleep 3

# Check deployment status
echo "Checking deployment status:"
PODS_STATUS=$(sudo k3s kubectl get pods -n plone --no-headers)
echo "$PODS_STATUS"

# Count ready pods
TOTAL_PODS=$(echo "$PODS_STATUS" | wc -l)
READY_PODS=$(echo "$PODS_STATUS" | grep -c "Running" || true)

if [ "$READY_PODS" -eq "$TOTAL_PODS" ]; then
    echo -e "\n${GREEN}All pods are running!${NC}"
else
    echo -e "\n${YELLOW}Some pods are still starting up...${NC}"
    echo "Run './scripts/status.sh' to check progress"
fi

# Display access information
echo ""
echo -e "${GREEN}Access Information:${NC}"
echo "────────────────────────────────────"

if [ "$USE_INGRESS" = true ]; then
    # Get node IP
    NODE_IP=$(sudo k3s kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo "URL: http://$NODE_IP"
    echo "Port: 80 (standard HTTP)"
    echo ""
    echo "Note: If using a cloud provider, use your server's public IP"
else
    echo "URL: http://$PLONE_HOST:$PLONE_PORT"
    echo ""
    echo "Access via:"
    echo "  - http://localhost:$PLONE_PORT (local)"
    echo "  - http://<server-ip>:$PLONE_PORT (remote)"
fi

echo ""
echo "Default credentials: admin / admin"
echo ""
echo "Use './scripts/status.sh' to check detailed status"
echo "Use './scripts/cleanup.sh' to remove all resources"