# Cloud Provider Deployment Guide

This guide covers specific instructions for deploying Plone on k3s across different cloud providers.

## Table of Contents
- [Hetzner Cloud](#hetzner-cloud)
- [DigitalOcean](#digitalocean)
- [AWS EC2](#aws-ec2)
- [Azure](#azure)
- [Google Cloud Platform](#google-cloud-platform)

## General Cloud Considerations

Before deploying on any cloud provider:

1. **Server Requirements**
   - Minimum: 2 vCPUs, 4GB RAM
   - Recommended: 4 vCPUs, 8GB RAM
   - Storage: 20GB+ SSD

2. **Network Security**
   - Open ports: 22 (SSH), 6443 (k3s API), 80/443 (HTTP/HTTPS)
   - For NodePort: Also open port 30080
   - Configure firewall rules appropriately

3. **Access Method**
   - **NodePort**: Works immediately, requires port 30080 open
   - **Ingress**: Uses port 80, better for production

## Hetzner Cloud

### Creating a Server

```bash
# Using Hetzner CLI
hcloud server create \
  --name plone-k3s \
  --type cx21 \
  --image ubuntu-22.04 \
  --ssh-key your-key
```

### Firewall Configuration

```bash
# Create firewall
hcloud firewall create --name plone-k3s

# Add rules
hcloud firewall add-rule plone-k3s \
  --direction in --source-ips 0.0.0.0/0 \
  --protocol tcp --port 22

hcloud firewall add-rule plone-k3s \
  --direction in --source-ips 0.0.0.0/0 \
  --protocol tcp --port 80

hcloud firewall add-rule plone-k3s \
  --direction in --source-ips 0.0.0.0/0 \
  --protocol tcp --port 443

hcloud firewall add-rule plone-k3s \
  --direction in --source-ips 0.0.0.0/0 \
  --protocol tcp --port 30080

# Apply to server
hcloud firewall apply-to-resource plone-k3s --type server --server plone-k3s
```

### Floating IP Configuration

If using a Hetzner Floating IP:

1. **Assign Floating IP**
   ```bash
   hcloud floating-ip assign floating-ip-id server-name
   ```

2. **Configure on Server**
   ```bash
   # SSH to server
   ssh root@server-ip

   # Add floating IP to network interface
   ip addr add floating-ip/32 dev eth0
   
   # Make persistent (Ubuntu)
   cat >> /etc/netplan/60-floating-ip.yaml <<EOF
   network:
     version: 2
     ethernets:
       eth0:
         addresses:
           - floating-ip/32
   EOF
   
   netplan apply
   ```

### Deployment

```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Clone deployment
git clone <your-repo> plone-k3s-deployment
cd plone-k3s-deployment

# Deploy with Ingress (recommended for Hetzner)
./scripts/deploy.sh --ingress

# Or configure for specific IP
./scripts/configure.sh --host your-floating-ip --port 80
./scripts/deploy.sh --ingress
```

## DigitalOcean

### Creating a Droplet

```bash
# Using doctl
doctl compute droplet create plone-k3s \
  --size s-2vcpu-4gb \
  --image ubuntu-22-04-x64 \
  --region fra1 \
  --ssh-keys your-key-id
```

### Firewall Configuration

```bash
# Create firewall
doctl compute firewall create --name plone-k3s \
  --inbound-rules "protocol:tcp,ports:22,sources:0.0.0.0/0 protocol:tcp,ports:80,sources:0.0.0.0/0 protocol:tcp,ports:443,sources:0.0.0.0/0 protocol:tcp,ports:30080,sources:0.0.0.0/0"

# Apply to droplet
doctl compute firewall add-droplets firewall-id --droplet-ids droplet-id
```

### Reserved IP (Optional)

```bash
# Create reserved IP
doctl compute reserved-ip create --region fra1

# Assign to droplet
doctl compute reserved-ip-action assign ip-address --droplet-id droplet-id
```

### Deployment

```bash
# SSH to droplet
ssh root@droplet-ip

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Deploy Plone
git clone <your-repo> plone-k3s-deployment
cd plone-k3s-deployment
./scripts/deploy.sh --ingress
```

## AWS EC2

### Launch Instance

1. **Choose AMI**: Ubuntu Server 22.04 LTS
2. **Instance Type**: t3.medium (minimum)
3. **Security Group**:
   ```
   - SSH (22) from your IP
   - HTTP (80) from anywhere
   - HTTPS (443) from anywhere
   - Custom TCP (30080) from anywhere
   - Custom TCP (6443) from anywhere
   ```

### Using AWS CLI

```bash
# Create security group
aws ec2 create-security-group \
  --group-name plone-k3s \
  --description "Plone k3s deployment"

# Add rules
aws ec2 authorize-security-group-ingress \
  --group-name plone-k3s \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name plone-k3s \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name plone-k3s \
  --protocol tcp --port 30080 --cidr 0.0.0.0/0

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.medium \
  --key-name your-key \
  --security-groups plone-k3s
```

### Elastic IP (Optional)

```bash
# Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Associate with instance
aws ec2 associate-address \
  --instance-id i-instance-id \
  --allocation-id eipalloc-allocation-id
```

### Deployment

```bash
# SSH to instance
ssh ubuntu@instance-ip

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Deploy Plone
git clone <your-repo> plone-k3s-deployment
cd plone-k3s-deployment

# For Elastic IP or public DNS
./scripts/configure.sh --host ec2-public-dns.compute.amazonaws.com --port 80
./scripts/deploy.sh --ingress
```

## Azure

### Create VM

```bash
# Create resource group
az group create --name plone-rg --location westeurope

# Create VM
az vm create \
  --resource-group plone-rg \
  --name plone-k3s \
  --image UbuntuLTS \
  --size Standard_B2s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub

# Open ports
az vm open-port --port 80 --resource-group plone-rg --name plone-k3s
az vm open-port --port 443 --resource-group plone-rg --name plone-k3s
az vm open-port --port 30080 --resource-group plone-rg --name plone-k3s --priority 1001
```

### Public IP Configuration

```bash
# Get public IP
az vm list-ip-addresses \
  --resource-group plone-rg \
  --name plone-k3s \
  --output table
```

### Deployment

```bash
# SSH to VM
ssh azureuser@public-ip

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Deploy Plone
git clone <your-repo> plone-k3s-deployment
cd plone-k3s-deployment
./scripts/deploy.sh --ingress
```

## Google Cloud Platform

### Create Instance

```bash
# Create firewall rules
gcloud compute firewall-rules create plone-k3s \
  --allow tcp:22,tcp:80,tcp:443,tcp:30080

# Create instance
gcloud compute instances create plone-k3s \
  --machine-type e2-medium \
  --image-family ubuntu-2204-lts \
  --image-project ubuntu-os-cloud \
  --boot-disk-size 20GB \
  --tags plone-k3s
```

### Static IP (Optional)

```bash
# Reserve static IP
gcloud compute addresses create plone-ip --region us-central1

# Get the IP
gcloud compute addresses describe plone-ip --region us-central1

# Assign to instance (done during creation or update)
```

### Deployment

```bash
# SSH to instance
gcloud compute ssh plone-k3s

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Deploy Plone
git clone <your-repo> plone-k3s-deployment
cd plone-k3s-deployment
./scripts/deploy.sh --ingress
```

## Common Issues by Cloud Provider

### Hetzner
- **Floating IP not working**: Ensure IP is configured on network interface
- **Firewall blocking**: Check both Hetzner firewall and ufw/iptables

### DigitalOcean
- **Reserved IP**: May need to wait for DNS propagation
- **Firewall**: Ensure firewall is attached to droplet

### AWS
- **Security Groups**: Most common issue, double-check all ports
- **Instance type**: t3.micro may be too small, use t3.medium

### Azure
- **NSG Rules**: Network Security Group rules can be complex
- **Public IP**: Ensure VM has public IP assigned

### GCP
- **Firewall tags**: Ensure instance has correct network tags
- **IAP**: May interfere with direct access, configure accordingly

## SSL/TLS Setup

For production deployments with HTTPS:

1. **Install cert-manager**
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

2. **Create ClusterIssuer**
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-prod
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: your-email@example.com
       privateKeySecretRef:
         name: letsencrypt-prod
       solvers:
       - http01:
           ingress:
             class: traefik
   ```

3. **Update Ingress**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: plone-ingress
     namespace: plone
     annotations:
       cert-manager.io/cluster-issuer: letsencrypt-prod
   spec:
     tls:
     - hosts:
       - your-domain.com
       secretName: plone-tls
     rules:
     - host: your-domain.com
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

## Monitoring and Logs

Access logs across all providers:

```bash
# View all pods
sudo k3s kubectl get pods -n plone

# View logs
sudo k3s kubectl logs -f deployment/plone-backend -n plone
sudo k3s kubectl logs -f deployment/nginx -n plone

# Check events
sudo k3s kubectl get events -n plone --sort-by='.lastTimestamp'
```

## Support

For provider-specific issues:
- Check cloud provider documentation
- Review firewall/security group settings
- Ensure correct IP configuration
- Validate DNS settings if using domain names