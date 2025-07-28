# Fixing CORS Issues in Plone k3s Deployment

## The Problem
The Volto frontend needs to make API calls from the browser to the Plone backend. Without proper configuration, you'll see CORS errors because:
1. The frontend tries to access the API at the wrong URL
2. The backend doesn't include necessary CORS headers

## The Solution

### Quick Fix for localhost:30080
Run the update script:
```bash
./update-plone-cors.sh
```

This will:
- Update the frontend to use `http://localhost:30080/++api++` for API calls
- Add CORS headers to nginx configuration
- Restart the affected pods

### For Different Environments

If you're deploying to a different host/port, use the configurable version:

1. Edit the ConfigMap in `plone-frontend-configurable.yaml`:
   ```yaml
   data:
     PLONE_EXTERNAL_URL: "http://your-domain:your-port"
   ```

2. Apply the configuration:
   ```bash
   sudo k3s kubectl apply -f plone-frontend-configurable.yaml
   ```

### Using with Ingress

For production with k3s Traefik ingress:

1. Create an ingress resource:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: plone-ingress
     namespace: plone
   spec:
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

2. Update the ConfigMap:
   ```yaml
   data:
     PLONE_EXTERNAL_URL: "https://plone.example.com"
   ```

## Key Environment Variables

- `RAZZLE_INTERNAL_API_PATH`: Used by Volto SSR to connect to backend (internal k8s service)
- `RAZZLE_API_PATH`: Used by browser to make API calls (must be publicly accessible)
- `RAZZLE_LEGACY_TRAVERSE`: Enables `++api++` traversal syntax

## Testing

After applying changes:
1. Check frontend logs: `sudo k3s kubectl logs -f deployment/plone-frontend -n plone`
2. Open browser developer tools and check Network tab for API calls
3. API calls should go to `http://localhost:30080/++api++/*`

## Troubleshooting

If CORS errors persist:
1. Clear browser cache
2. Check nginx logs: `sudo k3s kubectl logs -f deployment/nginx -n plone`
3. Verify API is accessible: `curl http://localhost:30080/++api++/@site`