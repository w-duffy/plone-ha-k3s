# Plone CMS on k3s - Production Ready Deployment

A complete Kubernetes deployment of Plone CMS using k3s, designed for both local development and remote VM deployment.

## Architecture Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│   Browser   │────▶│    Nginx    │────▶│   Volto     │────▶│    Plone     │
│             │     │  (NodePort) │     │  (Frontend) │     │  (Backend)   │
└─────────────┘     └─────────────┘     └─────────────┘     └──────────────┘
                           │                                          │
                           │                                          ▼
                           │                                   ┌──────────────┐
                           └──────────────────────────────────▶│  PostgreSQL  │
                                                              └──────────────┘
```

## Directory Structure

```
plone-k3s-deployment/
├── README.md                    # This file
├── config/
│   └── deployment.env          # Environment-specific configuration
├── k8s/
│   ├── 01-namespace.yaml       # Plone namespace
│   ├── 02-postgres.yaml        # PostgreSQL with PVC
│   ├── 03-backend.yaml         # Plone backend service
│   ├── 04-frontend.yaml        # Volto frontend service
│   ├── 05-nginx-config.yaml    # Nginx ConfigMap
│   └── 06-nginx.yaml           # Nginx deployment
├── scripts/
│   ├── deploy.sh               # Main deployment script
│   ├── configure.sh            # Configuration helper
│   ├── status.sh               # Check deployment status
│   └── cleanup.sh              # Remove all resources
└── docs/
    ├── DEPLOYMENT.md           # Deployment guide
    ├── TROUBLESHOOTING.md      # Common issues and fixes
    └── DEVELOPMENT.md          # Local development guide
```

## Quick Start

### Local Development
```bash
# Deploy with NodePort (default - localhost:30080)
./scripts/deploy.sh

# Or use Ingress (port 80)
./scripts/deploy.sh --ingress
```

### Remote VM Deployment
```bash
# Configure for your VM's IP/domain
./scripts/configure.sh --host your-vm-ip --port 30080

# Deploy with NodePort
./scripts/deploy.sh

# Or deploy with Ingress (recommended for cloud)
./scripts/deploy.sh --ingress

# Validate deployment
./scripts/validate.sh

# Check status
./scripts/status.sh
```

## Components

- **PostgreSQL**: Database with persistent storage
- **Plone Backend**: Python CMS backend (v6.1)
- **Volto Frontend**: React-based UI
- **Nginx**: Reverse proxy with CORS handling

## Access Points

After deployment, access Plone at:
- Local: `http://localhost:30080`
- Remote: `http://your-vm-ip:30080`

Default credentials: `admin` / `admin`

## Requirements

- k3s installed and running
- kubectl configured
- 2GB+ RAM available
- Port 30080 accessible (for NodePort) or port 80 (for Ingress)

## Key Features

- 🚀 **Flexible Deployment**: Choose between NodePort (development) or Ingress (production)
- 🔍 **Auto-detection**: Automatically detects k3s Traefik installation
- ✅ **Validation**: Built-in health checks and deployment validation
- ☁️ **Cloud Ready**: Guides for AWS, Azure, GCP, Hetzner, DigitalOcean
- 🛡️ **Production Ready**: CORS handling, SSL support, scaling capabilities

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed instructions.  
See [docs/CLOUD-PROVIDERS.md](docs/CLOUD-PROVIDERS.md) for cloud-specific guides.