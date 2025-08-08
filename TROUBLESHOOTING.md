# Space Monster Todo Troubleshooting Guide

## Common Issues and Solutions

### 1. Application Not Loading / 503 Service Unavailable

**Symptoms:**
- Browser shows "503 Service Temporarily Unavailable"
- Application doesn't load at your configured domain

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n space-monster-todo

# Check service endpoints
kubectl get endpoints -n space-monster-todo

# Check ingress configuration
kubectl describe ingress -n space-monster-todo
```

**Common Causes & Solutions:**

#### A. Service Selector Mismatch
**Problem:** Service selector doesn't match deployment labels
```bash
# Check deployment labels
kubectl get deployment space-monster-todo -n space-monster-todo -o yaml | grep -A 5 labels

# Check service selector
kubectl get service space-monster-todo-service -n space-monster-todo -o yaml | grep -A 5 selector
```

**Solution:** Update service selector to match deployment labels:
```bash
./deploy-simple.sh update
```

#### B. Pods Not Running
**Problem:** Pods are in CrashLoopBackOff or Pending state
```bash
# Check pod events
kubectl describe pods -n space-monster-todo

# Check pod logs
kubectl logs -n space-monster-todo -l app=space-monster-todo
```

**Solutions:**
- **ConfigMap Issues:** Recreate ConfigMap with correct content
- **Resource Limits:** Increase memory/CPU limits in deployment
- **Image Pull Errors:** Verify nginx:alpine is accessible

### 2. ConfigMap Content Issues

**Symptoms:**
- Application loads but shows nginx default page
- Missing Space Monster styles/functionality

**Diagnosis:**
```bash
# Check ConfigMap exists and has content
kubectl get configmap space-monster-html -n space-monster-todo -o yaml

# Verify content is mounted in pod
kubectl exec -n space-monster-todo deployment/space-monster-todo -- ls -la /usr/share/nginx/html/
kubectl exec -n space-monster-todo deployment/space-monster-todo -- head -10 /usr/share/nginx/html/index.html
```

**Solutions:**
```bash
# Recreate ConfigMap from source file
kubectl create configmap space-monster-html \
  --from-file=index.html=public/index.html \
  --namespace=space-monster-todo \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment to pick up changes
kubectl rollout restart deployment/space-monster-todo -n space-monster-todo
```

### 3. SSL/TLS Certificate Issues

**Symptoms:**
- Certificate warnings in browser
- HTTPS not working

**Diagnosis:**
```bash
# Check certificate status
kubectl get certificates -n space-monster-todo
kubectl describe certificate space-monster-todo-tls -n space-monster-todo

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

**Solutions:**
- **Certificate Not Ready:** Wait for Let's Encrypt validation (can take 5-10 minutes)
- **DNS Issues:** Verify your domain points to correct IP
- **Rate Limits:** Let's Encrypt has rate limits; wait before retrying

### 4. Performance Issues

**Symptoms:**
- Slow loading times
- Animations stuttering

**Diagnosis:**
```bash
# Check resource usage
kubectl top pods -n space-monster-todo

# Check HPA if enabled
kubectl get hpa -n space-monster-todo
```

**Solutions:**
- **Resource Limits:** Increase CPU/memory in deployment
- **CDN Issues:** React/Bootstrap loading from CDN may be slow
- **Browser Cache:** Clear browser cache and reload

### 5. Deployment Script Issues

**Symptoms:**
- `./deploy-simple.sh` fails with errors

**Common Solutions:**

#### A. Permission Denied
```bash
chmod +x deploy-simple.sh
```

#### B. HTML File Not Found
```bash
# Verify file exists
ls -la public/index.html

# Check file has content
head -5 public/index.html
```

#### C. kubectl Not Configured
```bash
# Test cluster connectivity
kubectl cluster-info

# Check current context
kubectl config current-context

# List available contexts
kubectl config get-contexts
```

### 6. Namespace Issues

**Symptoms:**
- Resources not found
- Permission denied errors

**Diagnosis:**
```bash
# Check if namespace exists
kubectl get namespace space-monster-todo

# Check resources in namespace
kubectl get all -n space-monster-todo
```

**Solutions:**
```bash
# Create namespace if missing
kubectl create namespace space-monster-todo

# Set default namespace (optional)
kubectl config set-context --current --namespace=space-monster-todo
```

## Diagnostic Commands

### Quick Health Check
```bash
# Run all diagnostic commands
kubectl get all -n space-monster-todo
kubectl get ingress -n space-monster-todo
kubectl get configmap -n space-monster-todo
```

### Pod Debugging
```bash
# Get detailed pod information
kubectl describe pod -n space-monster-todo -l app=space-monster-todo

# Check pod logs
kubectl logs -n space-monster-todo -l app=space-monster-todo --tail=50

# Access pod shell
kubectl exec -it -n space-monster-todo deployment/space-monster-todo -- sh
```

### Network Debugging
```bash
# Test service connectivity
kubectl port-forward -n space-monster-todo service/space-monster-todo-service 8080:80

# Test from another pod
kubectl run debug --image=alpine --rm -it -- sh
# Inside pod: wget -O- space-monster-todo-service.space-monster-todo.svc.cluster.local
```

### Configuration Debugging
```bash
# Export all resources for review
kubectl get all -n space-monster-todo -o yaml > debug-export.yaml

# Check resource events
kubectl get events -n space-monster-todo --sort-by='.lastTimestamp'
```

## Emergency Recovery

### Complete Reset
If everything is broken, start fresh:

```bash
# Delete entire deployment
kubectl delete namespace space-monster-todo

# Recreate namespace
kubectl create namespace space-monster-todo

# Redeploy everything
./deploy-simple.sh deploy
```

### Rollback Deployment
```bash
# Check rollout history
kubectl rollout history deployment/space-monster-todo -n space-monster-todo

# Rollback to previous version
kubectl rollout undo deployment/space-monster-todo -n space-monster-todo

# Rollback to specific revision
kubectl rollout undo deployment/space-monster-todo -n space-monster-todo --to-revision=1
```

## Monitoring Commands

### Real-time Monitoring
```bash
# Watch pod status
watch kubectl get pods -n space-monster-todo

# Follow logs
kubectl logs -n space-monster-todo -l app=space-monster-todo -f

# Monitor events
kubectl get events -n space-monster-todo -w
```

### Application Testing
```bash
# Test application directly
curl -k https://${DOMAIN} | head -10

# Test from inside cluster
kubectl run curl-test --image=curlimages/curl --rm -it -- \
  curl space-monster-todo-service.space-monster-todo.svc.cluster.local
```

## Performance Tuning

### Resource Optimization
```yaml
# Increase resources if needed
resources:
  limits:
    memory: "256Mi"
    cpu: "200m"
  requests:
    memory: "128Mi"
    cpu: "100m"
```

### Scaling
```bash
# Scale up replicas
kubectl scale deployment space-monster-todo -n space-monster-todo --replicas=3

# Enable auto-scaling
kubectl autoscale deployment space-monster-todo -n space-monster-todo --min=2 --max=5 --cpu-percent=70
```

## Contact Information

For issues not covered in this guide:
- Check application logs: `kubectl logs -n space-monster-todo -l app=space-monster-todo`
- Review Kubernetes events: `kubectl get events -n space-monster-todo`
- Test deployment script: `./deploy-simple.sh status`

---

**Last Updated:** 2025-08-08  
**Version:** 1.0  
**Compatibility:** Kubernetes 1.20+