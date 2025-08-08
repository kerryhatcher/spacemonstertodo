# Space Monster Todo Deployment Guide

## Overview

This document provides step-by-step instructions for deploying the Space Monster Todo List application to Kubernetes at your configured domain.

## Architecture

The application uses a **single-file HTML architecture** with:
- Complete React application with inline JavaScript
- All CSS styles embedded
- No external dependencies except CDN resources
- Kubernetes ConfigMap for static content delivery
- Nginx for web server

## Prerequisites

- Kubernetes cluster access with `kubectl` configured
- Kubernetes MCP server access (or manual kubectl commands)
- Application source code in `/public/index.html`

## Deployment Process

### Step 1: Prepare the Application

Ensure the complete application is in the single HTML file:
```bash
# Verify the application file exists and contains full content
ls -la public/index.html
head -20 public/index.html  # Should show React imports and space monster styles
```

### Step 2: Create Kubernetes ConfigMap

The application content is deployed via a Kubernetes ConfigMap:

```yaml
# k8s-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: space-monster-html
  namespace: space-monster-todo
data:
  index.html: |
    [FULL HTML CONTENT FROM public/index.html]
```

Apply the ConfigMap:
```bash
kubectl apply -f k8s-configmap.yaml
```

### Step 3: Deploy Application Pods

Create deployment with nginx pods that mount the ConfigMap:

```yaml
# k8s-deployment-pods.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: space-monster-todo
  namespace: space-monster-todo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: space-monster-todo
  template:
    metadata:
      labels:
        app: space-monster-todo
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
          requests:
            memory: "64Mi"
            cpu: "50m"
      volumes:
      - name: html-volume
        configMap:
          name: space-monster-html
```

### Step 4: Update Service Configuration

Ensure the service selector matches the deployment labels:

```yaml
# k8s-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: space-monster-todo-service
  namespace: space-monster-todo
  labels:
    app: space-monster-todo
    component: frontend
    service: web
  annotations:
    description: Service for Space Monster Todo List frontend
spec:
  selector:
    app: space-monster-todo  # Must match deployment labels
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
```

### Step 5: Verify Deployment

Check that all components are running:

```bash
# Check pods are running
kubectl get pods -n space-monster-todo

# Check service endpoints
kubectl get svc -n space-monster-todo

# Check ingress status
kubectl get ingress -n space-monster-todo

# Test application content
kubectl exec -n space-monster-todo deployment/space-monster-todo -- head -10 /usr/share/nginx/html/index.html
```

## Quick Update Process

For fast updates to the application:

1. **Update the application file:**
   ```bash
   # Edit public/index.html with your changes
   ```

2. **Regenerate and apply ConfigMap:**
   ```bash
   # Update the ConfigMap with new content
   kubectl create configmap space-monster-html \
     --from-file=index.html=public/index.html \
     --namespace=space-monster-todo \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

3. **Restart pods to pick up changes:**
   ```bash
   kubectl rollout restart deployment/space-monster-todo -n space-monster-todo
   ```

4. **Verify update:**
   ```bash
   kubectl rollout status deployment/space-monster-todo -n space-monster-todo
   ```

## Existing Infrastructure

The following resources are already configured and should not need changes:

### Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: space-monster-todo
```

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: space-monster-todo-ingress
  namespace: space-monster-todo
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  rules:
  - host: ${DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: space-monster-todo-service
            port:
              number: 80
  tls:
  - hosts:
    - ${DOMAIN}
    secretName: space-monster-todo-tls
```

## Directory Structure

```
/home/kwhatcher/projects/demo/
├── public/
│   └── index.html              # Main application file
├── k8s-configmap.yaml         # Generated ConfigMap
├── k8s-deployment.yaml        # Pod deployment configuration  
├── Dockerfile                 # Container build file (optional)
├── DEPLOYMENT.md              # This documentation
└── reports/                   # Project requirements and planning
    ├── jim-bobb-space-monster-todo-prd-2025-08-08.md
    ├── sarah-mitchell-space-monster-todo-enhanced-prd-2025-08-08.md
    └── space-monster-todo-final-prd-2025-08-08.md
```

## Troubleshooting

### Pods Not Running
- Check ConfigMap exists: `kubectl get configmap -n space-monster-todo`
- Verify service selector matches deployment labels
- Check resource quotas and node capacity

### Application Not Loading
- Verify ingress is pointing to correct service name
- Check service endpoints: `kubectl describe service space-monster-todo-service -n space-monster-todo`
- Test pod directly: `kubectl exec -n space-monster-todo deployment/space-monster-todo -- curl localhost`

### SSL/TLS Issues
- Check certificate status: `kubectl describe certificate -n space-monster-todo`
- Verify ingress annotations for cert-manager
- Check Let's Encrypt certificate issuer

### Content Not Updating
- Restart deployment after ConfigMap changes
- Clear browser cache
- Verify ConfigMap was updated with new content

## Performance Considerations

- **Single HTML file:** ~19KB compressed, loads instantly
- **CDN dependencies:** React, Bootstrap loaded from CDN for caching
- **localStorage:** All data stored client-side, no backend required
- **Static content:** Highly cacheable, scales with CDN

## Security Notes

- No backend database or user authentication
- All data stored in browser localStorage
- Static content only, minimal attack surface
- Standard nginx security headers applied via ingress

---

**Last Updated:** 2025-08-08  
**Application Version:** Space Monster Todo v1.0  
**Kubernetes Cluster:** ${DOMAIN}