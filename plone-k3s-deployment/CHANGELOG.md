# Changelog

## v1.0.0 - Initial Release

### Features
- **Flexible Deployment Modes**:
  - NodePort mode for local development (port 30080)
  - Ingress mode for production deployments (port 80)
  - Automatic detection of k3s Traefik installation
  
- **Complete Kubernetes Stack**:
  - PostgreSQL with persistent storage
  - Plone backend (v6.1) with REST API
  - Volto frontend with server-side rendering
  - Nginx reverse proxy with CORS handling
  
- **Deployment Automation**:
  - One-command deployment script with mode selection
  - Configuration script for different environments
  - Validation script for health checking
  - Status monitoring script
  - Clean uninstall script
  
- **Cloud Provider Support**:
  - Comprehensive guides for major cloud providers
  - Specific instructions for Hetzner, DigitalOcean, AWS, Azure, GCP
  - Floating/Elastic IP configuration
  - Firewall setup commands
  
- **Production Features**:
  - CORS headers properly configured
  - URL rewriting for API calls
  - Resource limits and requests
  - Scaling capabilities
  - SSL/TLS documentation

### Documentation
- Architecture overview with diagrams
- Step-by-step deployment guide
- Comprehensive troubleshooting guide
- Cloud provider specific instructions
- Development workflow documentation