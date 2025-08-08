#!/bin/bash

# Space Monster Todo Deployment Script
# Automates the deployment process for Kubernetes

set -e  # Exit on any error

# Configuration
NAMESPACE="space-monster-todo"
APP_NAME="space-monster-todo"
HTML_FILE="public/index.html"
CONFIGMAP_NAME="space-monster-html"
DEPLOYMENT_NAME="space-monster-todo"
SERVICE_NAME="space-monster-todo-service"
DOMAIN="${DOMAIN:-your-domain.com}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if HTML file exists
    if [ ! -f "$HTML_FILE" ]; then
        print_error "Application file $HTML_FILE not found!"
        exit 1
    fi
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl command not found!"
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster!"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create/update ConfigMap
update_configmap() {
    print_status "Creating/updating ConfigMap..."
    
    # Create ConfigMap from HTML file
    kubectl create configmap $CONFIGMAP_NAME \
        --from-file=index.html=$HTML_FILE \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "ConfigMap updated"
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application..."
    
    # Create deployment YAML
    cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
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
          name: $CONFIGMAP_NAME
EOF
    
    print_success "Deployment applied"
}

# Function to ensure service is configured
ensure_service() {
    print_status "Ensuring service configuration..."
    
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
    component: frontend
    service: web
  annotations:
    description: Service for Space Monster Todo List frontend
spec:
  selector:
    app: $APP_NAME
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
EOF
    
    print_success "Service configured"
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    print_status "Waiting for deployment to be ready..."
    
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s
    
    print_success "Deployment is ready"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check pods are running
    RUNNING_PODS=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME --field-selector=status.phase=Running --no-headers | wc -l)
    if [ $RUNNING_PODS -eq 0 ]; then
        print_error "No running pods found!"
        exit 1
    fi
    
    print_success "$RUNNING_PODS pods are running"
    
    # Test application content
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath="{.items[0].metadata.name}")
    CONTENT_CHECK=$(kubectl exec -n $NAMESPACE $POD_NAME -- head -1 /usr/share/nginx/html/index.html)
    
    if [[ $CONTENT_CHECK == *"Space Monster Todo"* ]]; then
        print_success "Application content verified"
    else
        print_warning "Could not verify application content"
    fi
}

# Function to show deployment info
show_info() {
    print_status "Deployment Information:"
    echo "=========================="
    echo "Namespace: $NAMESPACE"
    echo "Application: $APP_NAME"
    echo "URL: https://$DOMAIN"
    echo ""
    
    print_status "Pods:"
    kubectl get pods -n $NAMESPACE -l app=$APP_NAME
    echo ""
    
    print_status "Service:"
    kubectl get svc -n $NAMESPACE $SERVICE_NAME
    echo ""
    
    print_status "Ingress:"
    kubectl get ingress -n $NAMESPACE
}

# Main deployment function
main() {
    echo "=================================="
    echo "Space Monster Todo Deployment"
    echo "=================================="
    echo ""
    
    check_prerequisites
    update_configmap
    deploy_application
    ensure_service
    wait_for_deployment
    verify_deployment
    
    echo ""
    print_success "Deployment completed successfully!"
    echo ""
    
    show_info
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "update")
        print_status "Quick update mode..."
        check_prerequisites
        update_configmap
        kubectl rollout restart deployment/$DEPLOYMENT_NAME -n $NAMESPACE
        wait_for_deployment
        verify_deployment
        print_success "Update completed!"
        ;;
    "status")
        show_info
        ;;
    "logs")
        kubectl logs -n $NAMESPACE -l app=$APP_NAME --tail=100 -f
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  deploy  - Full deployment (default)"
        echo "  update  - Quick update (ConfigMap + restart)"
        echo "  status  - Show deployment status"
        echo "  logs    - Show application logs"
        echo "  help    - Show this help"
        echo ""
        echo "Prerequisites:"
        echo "  - kubectl configured with cluster access"
        echo "  - Application file at $HTML_FILE"
        echo "  - Kubernetes namespace '$NAMESPACE' exists"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac