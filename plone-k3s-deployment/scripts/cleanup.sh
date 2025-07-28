#!/bin/bash

# Cleanup script for Plone k3s deployment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Plone k3s Cleanup ===${NC}"
echo ""
echo "This will remove all Plone resources from your k3s cluster."
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Removing Plone namespace and all resources..."
if sudo k3s kubectl delete namespace plone --timeout=60s 2>/dev/null; then
    echo -e "${GREEN}✓ All resources removed${NC}"
else
    echo -e "${YELLOW}⚠ Namespace not found or already removed${NC}"
fi

echo ""
echo "Cleanup complete!"