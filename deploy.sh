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

# Function to show help
show_help() {
    echo "Space Monster Todo Deployment Script"
    echo "===================================="
    echo ""
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

# Build React application
build_react_app() {
    log_info "Building React application..."
    
    cd "${SCRIPT_DIR}"
    
    # Install dependencies
    log_info "Installing dependencies..."
    npm ci
    
    # Run tests
    log_info "Running tests..."
    npm test -- --coverage --watchAll=false
    
    # Build application
    log_info "Building application..."
    npm run build
    
    log_success "React application built successfully"
}

# Build Docker image
build_docker_image() {
    log_info "Building Docker image..."
    
    cd "${SCRIPT_DIR}"
    
    # Generate image tag
    local git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local image_tag="${APP_NAME}:${git_sha}-${timestamp}"
    
    # Build image
    log_info "Building image: ${image_tag}"
    docker build -t "${image_tag}" -t "${APP_NAME}:latest" .
    
    # Save image tag for later use
    echo "${image_tag}" > /tmp/space-monster-todo-image-tag
    
    log_success "Docker image built successfully: ${image_tag}"
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    log_info "Deploying to Kubernetes..."
    
    cd "${K8S_DIR}"
    
    # Get image tag
    local image_tag="${APP_NAME}:latest"
    if [[ -f /tmp/space-monster-todo-image-tag ]]; then
        image_tag=$(cat /tmp/space-monster-todo-image-tag)
    fi
    
    # Create namespace
    log_info "Creating namespace..."
    kubectl apply -f namespace.yaml
    
    # Apply ConfigMap
    log_info "Applying ConfigMap..."
    kubectl apply -f configmap.yaml
    
    # Update deployment with correct image
    log_info "Updating deployment with image: ${image_tag}"
    sed -i.bak "s|image: space-monster-todo:latest|image: ${image_tag}|g" deployment.yaml
    
    # Apply deployment
    log_info "Applying deployment..."
    kubectl apply -f deployment.yaml
    
    # Apply service
    log_info "Applying service..."
    kubectl apply -f service.yaml
    
    # Apply HPA
    log_info "Applying HPA..."
    kubectl apply -f hpa.yaml
    
    # Apply ingress
    log_info "Applying ingress..."
    kubectl apply -f ingress.yaml
    
    # Restore original deployment file
    mv deployment.yaml.bak deployment.yaml
    
    # Wait for deployment
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=300s
    
    log_success "Deployment completed successfully"
}

# Check deployment status
check_status() {
    log_info "Checking deployment status..."
    
    echo
    log_info "Namespace:"
    kubectl get namespace ${NAMESPACE} 2>/dev/null || log_warning "Namespace not found"
    
    echo
    log_info "Deployments:"
    kubectl get deployments -n ${NAMESPACE} 2>/dev/null || log_warning "No deployments found"
    
    echo
    log_info "Pods:"
    kubectl get pods -n ${NAMESPACE} 2>/dev/null || log_warning "No pods found"
    
    echo
    log_info "Services:"
    kubectl get services -n ${NAMESPACE} 2>/dev/null || log_warning "No services found"
    
    echo
    log_info "Ingress:"
    kubectl get ingress -n ${NAMESPACE} 2>/dev/null || log_warning "No ingress found"
    
    echo
    log_info "HPA:"
    kubectl get hpa -n ${NAMESPACE} 2>/dev/null || log_warning "No HPA found"
    
    echo
    log_info "Application should be available at: https://${DOMAIN}"
}

# Show logs
show_logs() {
    log_info "Showing application logs..."
    kubectl logs -n ${NAMESPACE} -l app=${APP_NAME} --tail=100 -f
}

# Clean up deployment
cleanup() {
    log_warning "Cleaning up deployment..."
    
    read -p "Are you sure you want to delete the entire deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
    
    cd "${K8S_DIR}"
    
    # Delete resources in reverse order
    kubectl delete -f ingress.yaml --ignore-not-found=true
    kubectl delete -f hpa.yaml --ignore-not-found=true
    kubectl delete -f service.yaml --ignore-not-found=true
    kubectl delete -f deployment.yaml --ignore-not-found=true
    kubectl delete -f configmap.yaml --ignore-not-found=true
    kubectl delete -f namespace.yaml --ignore-not-found=true
    
    log_success "Cleanup completed"
}

# Dry run
dry_run() {
    log_info "Performing dry run..."
    
    cd "${K8S_DIR}"
    
    echo "The following resources would be applied:"
    echo "========================================"
    
    for file in namespace.yaml configmap.yaml deployment.yaml service.yaml hpa.yaml ingress.yaml; do
        echo
        log_info "File: ${file}"
        kubectl apply -f "${file}" --dry-run=client -o yaml
    done
}

# Main execution
main() {
    local build_only=false
    local deploy_only=false
    local dry_run_mode=false
    local force_deploy=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -b|--build)
                build_only=true
                shift
                ;;
            -d|--deploy)
                deploy_only=true
                shift
                ;;
            -c|--clean)
                cleanup
                exit 0
                ;;
            -s|--status)
                check_status
                exit 0
                ;;
            -l|--logs)
                show_logs
                exit 0
                ;;
            --dry-run)
                dry_run
                exit 0
                ;;
            --force)
                force_deploy=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Execute based on options
    if [[ "${build_only}" == true ]]; then
        build_react_app
        build_docker_image
    elif [[ "${deploy_only}" == true ]]; then
        deploy_to_kubernetes
        check_status
    else
        # Full build and deploy
        build_react_app
        if build_docker_image || [[ "${force_deploy}" == true ]]; then
            deploy_to_kubernetes
            check_status
        else
            log_error "Build failed and --force not specified"
            exit 1
        fi
    fi
    
    log_success "Script completed successfully!"
}

# Run main function with all arguments
main "$@"