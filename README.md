# Plone CMS on Kubernetes (k3s)

A comprehensive solution for deploying [Plone CMS](https://plone.org) on Kubernetes using k3s, designed for both local development and production deployments.

## What is Plone?

Plone is an enterprise-grade, open-source Content Management System (CMS) built on Python. It features a modern React-based frontend (Volto) and a robust REST API backend, making it ideal for content-driven websites, intranets, and web applications.

## What This Repository Provides

This repository contains everything needed to deploy Plone CMS on a lightweight Kubernetes cluster (k3s). It includes:

- **Production-ready Kubernetes manifests** for the complete Plone stack
- **Automated deployment scripts** with flexible configuration options  
- **Comprehensive documentation** for various deployment scenarios
- **Cloud provider guides** for major platforms (AWS, Azure, GCP, DigitalOcean, Hetzner)
- **Development tools and utilities** for testing and troubleshooting

## Repository Structure

```
plone-k3s/
├── README.md                           # This file
├── plone-k3s-deployment/              # 🚀 Main deployment (START HERE)
│   ├── k8s/                           # Kubernetes manifests
│   ├── scripts/                       # Deployment automation
│   ├── docs/                          # Comprehensive guides
│   └── README.md                      # Detailed deployment instructions
└── plone-k3s-development-files/       # Development and testing files
```

## Quick Start

### For Production Deployment

Navigate to the main deployment directory:

```bash
cd plone-k3s-deployment
./scripts/deploy.sh --ingress    # Production with Traefik ingress
```

### For Local Development

```bash
cd plone-k3s-deployment  
./scripts/deploy.sh              # Local development with NodePort
```

Access Plone at `http://localhost:30080` (local) or your configured domain (production).

## Key Features

- **🚀 One-command deployment** - Get Plone running in minutes
- **🔄 Flexible modes** - NodePort for development, Ingress for production  
- **🛡️ Production-ready** - Includes PostgreSQL, persistent storage, and proper security
- **☁️ Cloud-optimized** - Works on any cloud provider or bare metal
- **📚 Comprehensive docs** - Detailed guides for every scenario
- **🔧 Easy configuration** - Environment-specific settings made simple

## Architecture

The deployment creates a complete Plone stack:

- **Volto Frontend** (React) - Modern, responsive user interface
- **Plone Backend** (Python) - Content management and REST API  
- **PostgreSQL** - Persistent database with backup capabilities
- **Nginx** - Reverse proxy with CORS and SSL termination
- **k3s** - Lightweight Kubernetes for container orchestration

## Getting Started

1. **Choose your deployment type:**
   - Local development: Use NodePort mode
   - Production/Cloud: Use Ingress mode

2. **Follow the deployment guide:**
   ```bash
   cd plone-k3s-deployment
   cat README.md  # Detailed instructions
   ```

3. **Configure for your environment:**
   ```bash
   ./scripts/configure.sh --help  # See configuration options
   ```

## Documentation

- **[Deployment Guide](plone-k3s-deployment/docs/DEPLOYMENT.md)** - Step-by-step instructions
- **[Cloud Providers](plone-k3s-deployment/docs/CLOUD-PROVIDERS.md)** - Platform-specific guides  
- **[Troubleshooting](plone-k3s-deployment/docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Architecture](plone-k3s-deployment/ARCHITECTURE.md)** - Technical deep dive

## Support

- **Issues**: Report problems via GitHub Issues
- **Plone Community**: [plone.org/community](https://plone.org/community)
- **Documentation**: [docs.plone.org](https://docs.plone.org)

## License

This deployment configuration is released under the MIT License. Plone itself is released under the GPL license.

---

**Ready to deploy Plone?** Start with [`plone-k3s-deployment/README.md`](plone-k3s-deployment/README.md) for detailed instructions.
