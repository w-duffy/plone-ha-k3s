# Plone k3s Architecture

## Overview

This deployment creates a complete Plone CMS stack on Kubernetes (k3s) with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ :30080 (NodePort)
┌─────────────────────────────────────────────────────────────┐
│                    Nginx (Reverse Proxy)                     │
│  - Routes /++api++/* to backend                            │
│  - Routes /* to frontend                                   │
│  - Handles CORS headers                                    │
│  - URL rewriting for API calls                             │
└──────────┬─────────────────────────────┬───────────────────┘
           │ :3000                       │ :8080
           ▼                             ▼
┌──────────────────────┐      ┌──────────────────────┐
│   Volto Frontend     │      │   Plone Backend      │
│  - React UI          │      │  - Python CMS        │
│  - Server-side       │◀─────│  - REST API          │
│    rendering         │ SSR  │  - Content mgmt      │
└──────────────────────┘      └───────────┬──────────┘
                                          │ :5432
                                          ▼
                              ┌──────────────────────┐
                              │    PostgreSQL        │
                              │  - Data persistence  │
                              │  - RelStorage        │
                              └──────────────────────┘
```

## Component Details

### 1. Nginx Reverse Proxy
- **Purpose**: Single entry point for all traffic
- **Port**: NodePort 30080 (configurable)
- **Features**:
  - Routes API calls (`/++api++/*`) to Plone backend
  - Routes everything else to Volto frontend
  - Adds CORS headers for cross-origin requests
  - Rewrites URLs to handle Volto's API call patterns

### 2. Volto Frontend
- **Image**: plone/plone-frontend:latest
- **Port**: 3000 (internal)
- **Purpose**: Modern React-based UI for Plone
- **Key configurations**:
  - `RAZZLE_INTERNAL_API_PATH`: For server-side rendering
  - Auto-detects browser URL for client-side API calls

### 3. Plone Backend
- **Image**: plone/plone-backend:6.1
- **Port**: 8080 (internal)
- **Purpose**: Core CMS functionality and REST API
- **Features**:
  - Content management
  - User authentication
  - RESTful API endpoints
  - Workflow management

### 4. PostgreSQL Database
- **Image**: postgres:15
- **Port**: 5432 (internal)
- **Purpose**: Data persistence
- **Storage**: PersistentVolumeClaim (2Gi)
- **Configuration**: RelStorage for better performance

## Networking

### Service Discovery
- All services communicate using Kubernetes DNS
- Service names: `backend`, `frontend`, `db`, `nginx`
- Namespace isolation: `plone`

### External Access
- NodePort service exposes port 30080
- Works with any k3s node IP
- Can be configured for different hosts/ports

### Internal Communication
```
frontend → backend:8080    (SSR API calls)
browser → nginx:30080 → backend:8080    (Client API calls)
browser → nginx:30080 → frontend:3000   (UI assets)
backend → db:5432          (Database queries)
```

## Key Design Decisions

### 1. Why NodePort instead of LoadBalancer?
- Works on any k3s installation (local or cloud)
- No external dependencies
- Predictable port assignment
- Easy to convert to Ingress for production

### 2. Why separate ConfigMaps?
- Nginx configuration can be updated without rebuilding
- Environment-specific settings isolated
- Easier troubleshooting

### 3. CORS Handling
- Nginx adds headers at proxy level
- Supports both simple and preflighted requests
- Works with any origin (configurable for production)

### 4. URL Rewriting
- Nginx rewrites `/login` → `/++api++/login`
- Handles Volto's API call patterns
- Transparent to the frontend

## Scaling Considerations

### Horizontal Scaling
- Backend: Can scale to multiple replicas
- Frontend: Can scale for better performance
- Database: Single instance (consider external DB for HA)

### Resource Limits
```yaml
Backend:  512Mi-1Gi memory, 250m-500m CPU
Frontend: 256Mi-512Mi memory, 100m-250m CPU
Nginx:    64Mi-128Mi memory, 50m-100m CPU
```

## Security Notes

1. **Default Credentials**: admin/admin (change immediately)
2. **Network Policies**: Not implemented (add for production)
3. **CORS**: Currently allows all origins (restrict for production)
4. **Database**: Password in plaintext (use Secrets for production)

## Customization Points

1. **External URL**: Configure via `deployment.env`
2. **Resource Limits**: Adjust in k8s manifests
3. **Image Versions**: Update in deployment files
4. **Persistence**: Modify PVC size as needed

## Comparison with Docker Compose

Key differences:
- Service discovery via DNS instead of container names
- PersistentVolumeClaims instead of Docker volumes
- Explicit resource management
- Built-in load balancing and scaling
- Declarative configuration