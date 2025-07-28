# Deployment Guide

This guide covers deploying Plone on k3s for different scenarios.

## Prerequisites

1. **k3s installed and running**
   ```bash
   # Install k3s (if not already installed)
   curl -sfL https://get.k3s.io | sh -
   
   # Start k3s
   sudo k3s server &
   ```

2. **System requirements**
   - 2GB+ RAM
   - 10GB+ disk space
   - Linux OS (Ubuntu, Debian, CentOS, etc.)

## Local Development Deployment

For local development on your machine:

```bash
# Deploy with defaults (localhost:30080)
cd plone-k3s-deployment
./scripts/deploy.sh

# Check status
./scripts/status.sh
```

Access at: http://localhost:30080

## Remote VM Deployment

For deploying on a remote VM (AWS, Azure, DigitalOcean, etc.):

### 1. Prepare the VM

```bash
# SSH into your VM
ssh user@your-vm-ip

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Start k3s
sudo systemctl enable k3s
sudo systemctl start k3s
```

### 2. Configure Firewall

Open required ports:
```bash
# For Ubuntu/Debian
sudo ufw allow 6443/tcp  # k3s API
sudo ufw allow 30080/tcp # Plone NodePort

# For CentOS/RHEL
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --reload
```

### 3. Deploy Plone

```bash
# Clone or copy the deployment files to the VM
git clone <your-repo> plone-k3s-deployment
cd plone-k3s-deployment

# Configure for your VM's public IP
./scripts/configure.sh --host YOUR_VM_PUBLIC_IP --port 30080

# Deploy
./scripts/deploy.sh

# Check status
./scripts/status.sh
```

### 4. Access Plone

Open in browser: `http://YOUR_VM_PUBLIC_IP:30080`

## Production Deployment with Domain

For production with a domain name:

### 1. DNS Setup

Point your domain to the VM's IP:
```
plone.example.com → YOUR_VM_IP
```

### 2. Configure with Domain

```bash
./scripts/configure.sh --host plone.example.com --port 30080
./scripts/deploy.sh
```

### 3. Optional: Setup Ingress with SSL

Create ingress configuration:
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: plone-ingress
  namespace: plone
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  tls:
  - hosts:
    - plone.example.com
    secretName: plone-tls
  rules:
  - host: plone.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

Apply:
```bash
sudo k3s kubectl apply -f ingress.yaml
```

## Scaling

Scale backend instances:
```bash
sudo k3s kubectl scale deployment plone-backend -n plone --replicas=3
```

Scale frontend instances:
```bash
sudo k3s kubectl scale deployment plone-frontend -n plone --replicas=2
```

## Backup and Restore

### Backup PostgreSQL
```bash
POD=$(sudo k3s kubectl get pods -n plone -l app=postgres -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl exec -n plone $POD -- pg_dump -U plone plone > plone-backup.sql
```

### Restore PostgreSQL
```bash
POD=$(sudo k3s kubectl get pods -n plone -l app=postgres -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl exec -i -n plone $POD -- psql -U plone plone < plone-backup.sql
```

## Monitoring

View real-time logs:
```bash
# All pods
sudo k3s kubectl logs -f -n plone -l app=plone-backend
sudo k3s kubectl logs -f -n plone -l app=plone-frontend

# Specific pod
sudo k3s kubectl logs -f deployment/nginx -n plone
```

## Security Considerations

1. **Change default passwords**
   - Edit `config/deployment.env` before deployment
   - Update PostgreSQL password
   - Change Plone admin password after first login

2. **Network policies**
   - Consider implementing k8s NetworkPolicies
   - Restrict pod-to-pod communication

3. **Resource limits**
   - Adjust memory/CPU limits in manifests
   - Monitor resource usage

4. **Regular updates**
   - Keep Plone images updated
   - Update k3s regularly