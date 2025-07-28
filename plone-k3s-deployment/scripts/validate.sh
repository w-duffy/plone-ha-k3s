#!/bin/bash

# Plone k3s Deployment Validation Script
# Checks for common issues and validates the deployment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Plone k3s Deployment Validation ===${NC}"
echo ""

# Track issues
ISSUES=0
WARNINGS=0

# Function to check condition
check() {
    local description=$1
    local command=$2
    local severity=${3:-"error"}  # error or warning
    
    echo -n "Checking $description... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        if [ "$severity" = "warning" ]; then
            echo -e "${YELLOW}⚠${NC}"
            ((WARNINGS++))
        else
            echo -e "${RED}✗${NC}"
            ((ISSUES++))
        fi
        return 1
    fi
}

# 1. Check k3s is running
check "k3s is running" "pgrep -f 'k3s server'"

# 2. Check kubectl access
check "kubectl access" "sudo k3s kubectl get nodes"

# 3. Check namespace exists
check "plone namespace exists" "sudo k3s kubectl get namespace plone"

# 4. Check all expected pods
echo ""
echo "Checking pod health:"
echo "─────────────────────"

# Expected pods
declare -A expected_pods=(
    ["postgres"]="app=postgres"
    ["plone-backend"]="app=plone-backend"
    ["plone-frontend"]="app=plone-frontend"
    ["nginx"]="app=nginx"
)

for pod_name in "${!expected_pods[@]}"; do
    selector="${expected_pods[$pod_name]}"
    echo -n "  $pod_name: "
    
    # Check if pod exists
    if ! sudo k3s kubectl get pods -n plone -l "$selector" --no-headers | grep -q .; then
        echo -e "${RED}Not found${NC}"
        ((ISSUES++))
        continue
    fi
    
    # Check pod status
    POD_STATUS=$(sudo k3s kubectl get pods -n plone -l "$selector" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ "$POD_STATUS" = "Running" ]; then
        echo -e "${GREEN}Running${NC}"
    else
        echo -e "${YELLOW}$POD_STATUS${NC}"
        ((WARNINGS++))
    fi
done

# 5. Check services
echo ""
echo "Checking services:"
echo "─────────────────────"

services=("db" "backend" "frontend" "nginx")
for service in "${services[@]}"; do
    check "  $service service" "sudo k3s kubectl get service $service -n plone" "warning"
done

# 6. Check nginx configuration
echo ""
check "nginx ConfigMap exists" "sudo k3s kubectl get configmap nginx-config -n plone"

# 7. Check external access configuration
echo ""
echo "Checking external access:"
echo "─────────────────────"

# Check for NodePort
if sudo k3s kubectl get service nginx -n plone -o jsonpath='{.spec.type}' 2>/dev/null | grep -q "NodePort"; then
    echo -e "  Mode: ${GREEN}NodePort${NC}"
    NODEPORT=$(sudo k3s kubectl get service nginx -n plone -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    echo "  Port: $NODEPORT"
    
    # Check if port is accessible
    if sudo ss -tlnp | grep -q ":$NODEPORT"; then
        echo -e "  Port status: ${GREEN}Listening${NC}"
    else
        echo -e "  Port status: ${YELLOW}Not listening (may take time to start)${NC}"
    fi
fi

# Check for Ingress
if sudo k3s kubectl get ingress -n plone 2>/dev/null | grep -q "plone-ingress"; then
    echo -e "  Mode: ${GREEN}Ingress${NC}"
    INGRESS_IP=$(sudo k3s kubectl get ingress plone-ingress -n plone -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$INGRESS_IP" ]; then
        echo "  IP: $INGRESS_IP"
    else
        echo -e "  IP: ${YELLOW}Pending${NC}"
    fi
fi

# Check for Traefik
check "  Traefik available" "sudo k3s kubectl get service -n kube-system traefik" "warning"

# 8. Check persistent volumes
echo ""
check "PostgreSQL PVC bound" "sudo k3s kubectl get pvc postgres-pvc -n plone -o jsonpath='{.status.phase}' | grep -q Bound"

# 9. Test connectivity
echo ""
echo "Testing connectivity:"
echo "─────────────────────"

# Get access URL
NODE_IP=$(sudo k3s kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
if sudo k3s kubectl get service nginx -n plone -o jsonpath='{.spec.type}' 2>/dev/null | grep -q "NodePort"; then
    NODEPORT=$(sudo k3s kubectl get service nginx -n plone -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    TEST_URL="http://$NODE_IP:$NODEPORT"
else
    TEST_URL="http://$NODE_IP"
fi

echo -n "  Testing $TEST_URL... "
if curl -sf -o /dev/null -m 5 "$TEST_URL"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${YELLOW}⚠ Not accessible yet${NC}"
    ((WARNINGS++))
fi

# 10. Check for common issues
echo ""
echo "Checking for common issues:"
echo "─────────────────────"

# Check for ImagePullBackOff
if sudo k3s kubectl get pods -n plone --no-headers | grep -q "ImagePull"; then
    echo -e "  ${RED}✗ Some pods have image pull issues${NC}"
    ((ISSUES++))
else
    echo -e "  ${GREEN}✓ No image pull issues${NC}"
fi

# Check for CrashLoopBackOff
if sudo k3s kubectl get pods -n plone --no-headers | grep -q "CrashLoop"; then
    echo -e "  ${RED}✗ Some pods are crash looping${NC}"
    ((ISSUES++))
else
    echo -e "  ${GREEN}✓ No crash loops detected${NC}"
fi

# Check events for errors
ERROR_EVENTS=$(sudo k3s kubectl get events -n plone --field-selector type=Warning --no-headers 2>/dev/null | wc -l)
if [ "$ERROR_EVENTS" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ $ERROR_EVENTS warning events in namespace${NC}"
    echo "    Run: sudo k3s kubectl get events -n plone --field-selector type=Warning"
fi

# Summary
echo ""
echo "─────────────────────"
if [ "$ISSUES" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your Plone deployment appears to be healthy."
    echo "Access it at: $TEST_URL"
elif [ "$ISSUES" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation completed with $WARNINGS warnings${NC}"
    echo ""
    echo "The deployment is functional but has some minor issues."
    echo "Run './scripts/status.sh' for more details."
else
    echo -e "${RED}✗ Validation failed with $ISSUES errors and $WARNINGS warnings${NC}"
    echo ""
    echo "Please check the errors above and:"
    echo "1. Run './scripts/status.sh' for detailed status"
    echo "2. Check logs: sudo k3s kubectl logs -n plone <pod-name>"
    echo "3. Review events: sudo k3s kubectl get events -n plone"
fi

exit $ISSUES