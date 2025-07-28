# Plone CMS on k3s - Local POC

This proof of concept demonstrates deploying Plone CMS on k3s (lightweight Kubernetes) instead of Docker Compose.

## Architecture

The deployment includes:
- **PostgreSQL**: Database backend with persistent storage
- **Plone Backend**: Python-based CMS backend (v6.1)
- **Volto Frontend**: React-based modern UI for Plone
- **Nginx**: Reverse proxy for routing requests

## Prerequisites

- k3s installed and running
- kubectl configured to connect to your k3s cluster

## Quick Start

1. Deploy all components:
   ```bash
   ./deploy-plone.sh
   ```

2. Check deployment status:
   ```bash
   kubectl get pods -n plone
   ```

3. Access Plone at http://localhost:30080

## Manual Deployment

```bash
# Create namespace
kubectl apply -f plone-namespace.yaml

# Deploy PostgreSQL
kubectl apply -f plone-postgres.yaml

# Deploy Plone backend
kubectl apply -f plone-backend.yaml

# Deploy Volto frontend
kubectl apply -f plone-frontend.yaml

# Configure and deploy Nginx
kubectl apply -f plone-nginx-config.yaml
kubectl apply -f plone-nginx.yaml
```

## Key Differences from Docker Compose

1. **Service Discovery**: k3s provides built-in DNS for service discovery
2. **Persistent Storage**: Uses PersistentVolumeClaims instead of Docker volumes
3. **Resource Management**: Explicit resource requests and limits
4. **Scaling**: Easy horizontal scaling with `kubectl scale`
5. **Load Balancing**: Built-in with k3s service types
6. **API Path Configuration**: Frontend auto-detects API URL from browser location

## Accessing Services

- **Main Site**: http://localhost:30080
- **Backend API**: http://localhost:30080/++api++
- **Classic Plone UI**: http://localhost:30080/@@plone-addsite

## Scaling

Scale the backend:
```bash
kubectl scale deployment plone-backend -n plone --replicas=3
```

Scale the frontend:
```bash
kubectl scale deployment plone-frontend -n plone --replicas=2
```

## Monitoring

View logs:
```bash
kubectl logs -f deployment/plone-backend -n plone
kubectl logs -f deployment/plone-frontend -n plone
```

## Troubleshooting

### CORS Issues
If you experience CORS errors:
1. Run `../fix-frontend-cors-final.sh` to ensure frontend uses auto-detected API paths
2. Clear your browser cache
3. The frontend will automatically use the correct API URL based on how you access it

### Connection Issues
- Ensure k3s is running: `sudo k3s kubectl get nodes`
- Check all pods are ready: `sudo k3s kubectl get pods -n plone`
- View logs: `sudo k3s kubectl logs -f deployment/[deployment-name] -n plone`

## Cleanup

Remove all resources:
```bash
kubectl delete namespace plone
```

## Production Considerations

For production use, consider:
- Using secrets for database credentials
- Implementing proper ingress with TLS
- Setting up backup strategies for PostgreSQL
- Using external persistent storage
- Implementing health checks and readiness probes
- Setting up monitoring and logging