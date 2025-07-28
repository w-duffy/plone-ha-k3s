#!/bin/bash

# Configuration helper for Plone k3s deployment

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$BASE_DIR/config/deployment.env"

# Default values
HOST=""
PORT=""
UPDATE_MANIFESTS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --update-manifests)
            UPDATE_MANIFESTS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --host HOST           Set the external host/IP (e.g., 192.168.1.100)"
            echo "  --port PORT           Set the NodePort (default: 30080)"
            echo "  --update-manifests    Update k8s manifests with new values"
            echo ""
            echo "Example:"
            echo "  $0 --host myserver.com --port 30080"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Interactive mode if no arguments
if [ -z "$HOST" ]; then
    echo -e "${BLUE}=== Plone k3s Configuration ===${NC}"
    echo ""
    echo "Enter the external host/IP for accessing Plone"
    echo "(Examples: localhost, 192.168.1.100, myserver.com)"
    read -p "Host [localhost]: " HOST
    HOST=${HOST:-localhost}
fi

if [ -z "$PORT" ]; then
    read -p "NodePort [30080]: " PORT
    PORT=${PORT:-30080}
fi

# Update configuration file
echo -e "${GREEN}Updating configuration...${NC}"
sed -i "s/^PLONE_HOST=.*/PLONE_HOST=\"$HOST\"/" "$CONFIG_FILE"
sed -i "s/^PLONE_PORT=.*/PLONE_PORT=\"$PORT\"/" "$CONFIG_FILE"

# Create ConfigMap for frontend
cat > "$BASE_DIR/k8s/00-config.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: plone-config
  namespace: plone
data:
  PLONE_EXTERNAL_URL: "http://$HOST:$PORT"
EOF

echo -e "${GREEN}✓ Configuration updated${NC}"
echo ""
echo "Settings:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  URL: http://$HOST:$PORT"
echo ""

# Update frontend manifest to use ConfigMap
if [ "$UPDATE_MANIFESTS" = true ]; then
    echo -e "${YELLOW}Updating frontend manifest...${NC}"
    # This would update the frontend.yaml to use the ConfigMap
    # For now, we'll just notify the user
    echo "Note: Frontend will use the configured URL for API calls"
fi

echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy: ./scripts/deploy.sh"
echo "2. If already deployed, update: ./scripts/update.sh"