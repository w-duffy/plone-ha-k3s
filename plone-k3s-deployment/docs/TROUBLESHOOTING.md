# Troubleshooting Guide

Common issues and solutions for Plone k3s deployment.

## Quick Validation

Run the validation script first:
```bash
./scripts/validate.sh
```

This will identify most common issues automatically.

## Deployment Issues

### k3s not running
```bash
# Check if k3s is running
ps aux | grep k3s

# Start k3s
sudo k3s server &

# Or as a service
sudo systemctl start k3s
```

### Pods not starting

Check pod status:
```bash
sudo k3s kubectl get pods -n plone
sudo k3s kubectl describe pod <pod-name> -n plone
```

Common causes:
- **ImagePullBackOff**: Network issues downloading images
- **CrashLoopBackOff**: Application crashing on startup
- **Pending**: Insufficient resources or PVC issues

### PostgreSQL connection errors

Check PostgreSQL logs:
```bash
sudo k3s kubectl logs -n plone -l app=postgres
```

Verify service:
```bash
sudo k3s kubectl get svc db -n plone
```

## Access Issues

### No Nginx pod running

**Symptom**: No nginx pod appears in `kubectl get pods -n plone`

**Cause**: The nginx YAML must contain ConfigMap, Service, and Deployment resources

**Solution**: Verify the nginx YAML includes all required resources:
```bash
# Check what's in the nginx file
cat k8s/05-nginx.yaml | grep "kind:"

# Should show:
# kind: ConfigMap
# kind: Service  
# kind: Deployment
```

### Cannot access Plone at NodePort

1. Check if port is listening:
   ```bash
   sudo ss -tlnp | grep 30080
   ```

2. Check service endpoints:
   ```bash
   sudo k3s kubectl get endpoints nginx -n plone
   ```

3. Try port forwarding as alternative:
   ```bash
   sudo k3s kubectl port-forward -n plone service/nginx 8080:80
   ```

### NodePort not accessible on cloud providers

**Symptom**: Can't access http://server-ip:30080 even though pods are running

**Cause**: k3s includes Traefik which may conflict, or cloud firewall blocking

**Solutions**:

1. **Use Ingress instead** (recommended):
   ```bash
   ./scripts/deploy.sh --ingress
   # Access on port 80 instead
   ```

2. **Check Traefik is not blocking**:
   ```bash
   sudo k3s kubectl get svc -n kube-system traefik
   ```

3. **Verify cloud firewall allows port 30080**:
   - AWS: Check Security Group
   - Azure: Check Network Security Group
   - GCP: Check Firewall Rules
   - Hetzner: Check Cloud Firewall

### CORS Errors

Symptoms: Browser console shows CORS policy errors

Solutions:
1. Ensure you're using the latest nginx configuration
2. Clear browser cache completely
3. Check nginx logs for errors:
   ```bash
   sudo k3s kubectl logs -n plone -l app=nginx
   ```

### API calls going to wrong port

If API calls go to port 80 instead of NodePort:
1. Check frontend environment:
   ```bash
   sudo k3s kubectl describe deployment plone-frontend -n plone | grep -A5 Environment
   ```

2. Restart frontend:
   ```bash
   sudo k3s kubectl rollout restart deployment/plone-frontend -n plone
   ```

## Performance Issues

### Slow response times

1. Check resource usage:
   ```bash
   sudo k3s kubectl top pods -n plone
   ```

2. Scale deployments:
   ```bash
   sudo k3s kubectl scale deployment plone-backend -n plone --replicas=2
   ```

3. Increase resource limits in manifests

### Database performance

Check PostgreSQL performance:
```bash
POD=$(sudo k3s kubectl get pods -n plone -l app=postgres -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl exec -n plone $POD -- psql -U plone -c "SELECT * FROM pg_stat_activity;"
```

## Debugging Commands

### View all resources
```bash
sudo k3s kubectl get all -n plone
```

### Check events
```bash
sudo k3s kubectl get events -n plone --sort-by='.lastTimestamp'
```

### Execute commands in pods
```bash
# Backend shell
sudo k3s kubectl exec -it deployment/plone-backend -n plone -- /bin/bash

# Test internal connectivity
sudo k3s kubectl exec -n plone deployment/nginx -- wget -O- http://backend:8080
```

### Check persistent volumes
```bash
sudo k3s kubectl get pvc -n plone
sudo k3s kubectl describe pvc postgres-pvc -n plone
```

## Common Error Messages

### "Connection refused" 
- Service not ready
- Wrong service name/port
- Network policy blocking

### "502 Bad Gateway"
- Backend not running
- Nginx can't reach backend
- Check nginx config

### "ECONNREFUSED" in frontend logs
- API path misconfigured
- Backend not accessible
- CORS issues

## Reset and Retry

If all else fails:
```bash
# Complete cleanup
./scripts/cleanup.sh

# Reconfigure
./scripts/configure.sh --host your-host --port 30080

# Fresh deployment
./scripts/deploy.sh
```

## Getting Help

1. Check pod logs:
   ```bash
   sudo k3s kubectl logs -f <pod-name> -n plone
   ```

2. Describe resources:
   ```bash
   sudo k3s kubectl describe <resource-type> <resource-name> -n plone
   ```

3. Export debug bundle:
   ```bash
   sudo k3s kubectl cluster-info dump --namespace plone --output-directory=/tmp/plone-debug
   ```