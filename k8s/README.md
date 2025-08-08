# Space Monster Todo List - Kubernetes Deployment

This directory contains all the Kubernetes configuration files and deployment tools for the Space Monster Todo List application.

## Overview

The Space Monster Todo List is deployed as a static React application served by nginx in a Kubernetes cluster. The deployment includes:

- **Multi-stage Docker build** for optimized production images
- **nginx configuration** with security headers, gzip compression, and caching
- **Kubernetes deployment** with health checks and resource limits
- **Horizontal Pod Autoscaler** for handling traffic spikes
- **Ingress with TLS/SSL** termination using cert-manager
- **Automated CI/CD pipeline** via GitHub Actions

## Architecture

```
Internet → Ingress (TLS) → Service → Deployment (3+ Pods) → nginx → React App
                                        ↓
                                   HPA (Auto-scaling)
```

## Prerequisites

Before deploying, ensure you have:

1. **Kubernetes cluster** with admin access
2. **kubectl** configured and connected to your cluster
3. **nginx-ingress-controller** installed in the cluster
4. **cert-manager** installed for TLS certificate management
5. **metrics-server** installed for HPA functionality
6. **Docker** for building images locally
7. **Node.js 18+** and **npm** for building the React app

### Installing Prerequisites

```bash
# Install nginx-ingress-controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Install metrics-server (if not already installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Quick Start

### Option 1: Using the Deployment Script (Recommended)

```bash
# Make script executable
chmod +x ../deploy.sh

# Full build and deploy
../deploy.sh

# Or use specific options
../deploy.sh --build      # Build only
../deploy.sh --deploy     # Deploy only
../deploy.sh --status     # Check status
../deploy.sh --logs       # Show logs
../deploy.sh --clean      # Clean up
```

### Option 2: Manual Deployment

```bash
# 1. Build the React application
cd ..
npm ci
npm run build

# 2. Build Docker image
docker build -t space-monster-todo:latest .

# 3. Deploy to Kubernetes
cd k8s
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
kubectl apply -f ingress.yaml

# 4. Wait for deployment
kubectl rollout status deployment/space-monster-todo -n space-monster-todo
```

### Option 3: Using Kustomize

```bash
# Apply all resources with kustomize
kubectl apply -k .

# Or build and preview first
kubectl kustomize . | kubectl apply -f -
```

## File Descriptions

| File | Description |
|------|-------------|
| `namespace.yaml` | Creates dedicated namespace for the application |
| `configmap.yaml` | nginx configuration with security headers and caching |
| `deployment.yaml` | Main application deployment with health checks |
| `service.yaml` | ClusterIP service to expose the deployment |
| `ingress.yaml` | Ingress with TLS configuration for ${DOMAIN} |
| `hpa.yaml` | Horizontal Pod Autoscaler for traffic scaling |
| `kustomization.yaml` | Kustomize configuration for easy management |
| `nginx.conf` | nginx configuration file (used in Docker build) |

## Configuration Details

### Resource Limits

- **CPU Request**: 100m (0.1 CPU cores)
- **CPU Limit**: 500m (0.5 CPU cores)
- **Memory Request**: 128Mi
- **Memory Limit**: 512Mi

### Auto-scaling Configuration

- **Minimum Replicas**: 3
- **Maximum Replicas**: 10
- **CPU Threshold**: 70%
- **Memory Threshold**: 80%

### Health Checks

- **Liveness Probe**: `/health` endpoint, 30s initial delay
- **Readiness Probe**: `/health` endpoint, 5s initial delay
- **Startup Probe**: `/health` endpoint, 10s initial delay

### Security Features

- **Non-root user**: nginx runs as user ID 101
- **Read-only root filesystem**: Prevents runtime modifications
- **Security headers**: CSP, X-Frame-Options, X-XSS-Protection, etc.
- **TLS termination**: Automatic HTTPS with Let's Encrypt certificates

## Domain Configuration

The application is configured to be accessible at your configured domain using the `${DOMAIN}` environment variable. To configure the domain:

1. Update the `host` field in `ingress.yaml`
2. Update the TLS configuration with the new domain
3. Ensure DNS points to your cluster's ingress controller

## Monitoring and Troubleshooting

### Check Deployment Status

```bash
# Overall status
../deploy.sh --status

# Detailed pod information
kubectl get pods -n space-monster-todo -o wide

# Check events
kubectl get events -n space-monster-todo --sort-by='.lastTimestamp'
```

### View Logs

```bash
# Application logs
../deploy.sh --logs

# Or manually
kubectl logs -n space-monster-todo -l app=space-monster-todo --tail=100 -f

# Specific pod logs
kubectl logs -n space-monster-todo <pod-name>
```

### Debug Network Issues

```bash
# Test service connectivity
kubectl port-forward service/space-monster-todo-service 8080:80 -n space-monster-todo

# Check ingress status
kubectl describe ingress space-monster-todo-ingress -n space-monster-todo

# Test from within cluster
kubectl run curl-test --image=curlimages/curl -it --rm -- sh
```

### Monitor Resource Usage

```bash
# Pod resource usage
kubectl top pods -n space-monster-todo

# HPA status
kubectl get hpa -n space-monster-todo

# Node resource usage
kubectl top nodes
```

## Scaling

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment space-monster-todo --replicas=5 -n space-monster-todo

# Scale using patch
kubectl patch deployment space-monster-todo -n space-monster-todo -p '{"spec":{"replicas":5}}'
```

### Auto-scaling

The HPA automatically scales based on CPU and memory usage. Monitor with:

```bash
kubectl get hpa -n space-monster-todo -w
```

## Updates and Rollbacks

### Rolling Updates

```bash
# Update image
kubectl set image deployment/space-monster-todo space-monster-todo=space-monster-todo:v2.0.0 -n space-monster-todo

# Check rollout status
kubectl rollout status deployment/space-monster-todo -n space-monster-todo
```

### Rollback

```bash
# View rollout history
kubectl rollout history deployment/space-monster-todo -n space-monster-todo

# Rollback to previous version
kubectl rollout undo deployment/space-monster-todo -n space-monster-todo

# Rollback to specific revision
kubectl rollout undo deployment/space-monster-todo --to-revision=2 -n space-monster-todo
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically:

1. **Builds** the React application
2. **Runs tests** and security scans
3. **Builds** and pushes Docker images to GitHub Container Registry
4. **Deploys** to Kubernetes
5. **Runs smoke tests** to verify deployment
6. **Sends notifications** to Slack

### Required Secrets

Configure these secrets in your GitHub repository:

| Secret | Description |
|--------|-------------|
| `KUBECONFIG` | Base64-encoded kubeconfig file |
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications (optional) |

### Triggering Deployments

- **Automatic**: Push to `main` branch
- **Manual**: Use GitHub Actions workflow dispatch
- **Pull Requests**: Builds and tests only

## Cleanup

To remove the entire deployment:

```bash
# Using the script
../deploy.sh --clean

# Manual cleanup
kubectl delete namespace space-monster-todo
```

## Best Practices Implemented

1. **Security**:
   - Non-root containers
   - Read-only filesystems
   - Security headers
   - TLS encryption

2. **Reliability**:
   - Multiple health checks
   - Pod anti-affinity
   - Graceful shutdowns
   - Resource limits

3. **Performance**:
   - nginx optimizations
   - Gzip compression
   - Static asset caching
   - HTTP/2 support

4. **Scalability**:
   - Horizontal Pod Autoscaler
   - Resource-based scaling
   - Load balancing

5. **Observability**:
   - Structured logging
   - Health endpoints
   - Prometheus annotations

## Support

For issues or questions:

1. Check the logs using `../deploy.sh --logs`
2. Verify cluster prerequisites are installed
3. Ensure DNS is properly configured
4. Check cert-manager for TLS issues

## License

This deployment configuration is part of the Space Monster Todo List project and follows the same MIT license.