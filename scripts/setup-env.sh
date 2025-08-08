#!/bin/bash

# Environment Setup Script for Space Monster Todo
# This script sets up environment variables and processes templates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if .env exists
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        print_warning ".env file not found. Creating from .env.example"
        cp .env.example .env
        print_warning "Please edit .env file with your configuration before proceeding"
        exit 1
    else
        print_error ".env.example file not found. Cannot create environment configuration."
        exit 1
    fi
fi

# Load environment variables
print_status "Loading environment variables from .env file..."
export $(grep -v '^#' .env | xargs)

# Validate required variables
REQUIRED_VARS=("DOMAIN")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable $var is not set"
        exit 1
    fi
done

# Process Kubernetes manifests with environment variable substitution
print_status "Processing Kubernetes manifests with environment substitution..."

# Create temporary directory for processed manifests
TEMP_DIR="/tmp/space-monster-todo-k8s"
mkdir -p "$TEMP_DIR"

# Process each manifest file
for file in k8s/*.yaml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        print_status "Processing $filename..."
        
        # Use envsubst to replace environment variables
        envsubst < "$file" > "$TEMP_DIR/$filename"
        
        # Verify the processed file
        if [ -s "$TEMP_DIR/$filename" ]; then
            print_success "Processed $filename"
        else
            print_error "Failed to process $filename"
            exit 1
        fi
    fi
done

print_success "All manifests processed successfully"
print_status "Processed files are in: $TEMP_DIR"

# Option to deploy processed manifests
if [ "$1" == "--deploy" ]; then
    print_status "Deploying processed manifests..."
    
    # Apply manifests in correct order
    kubectl apply -f "$TEMP_DIR/namespace.yaml"
    kubectl apply -f "$TEMP_DIR/configmap.yaml"
    kubectl apply -f "$TEMP_DIR/deployment.yaml"
    kubectl apply -f "$TEMP_DIR/service.yaml"
    kubectl apply -f "$TEMP_DIR/hpa.yaml"
    kubectl apply -f "$TEMP_DIR/ingress.yaml"
    
    print_success "Deployment completed"
    
    # Show deployment status
    echo ""
    print_status "Deployment Status:"
    kubectl get pods -n ${KUBE_NAMESPACE:-space-monster-todo}
    echo ""
    print_status "Application should be available at: https://$DOMAIN"
fi

# Cleanup option
if [ "$1" == "--cleanup" ]; then
    print_warning "Cleaning up processed manifest files..."
    rm -rf "$TEMP_DIR"
    print_success "Cleanup completed"
fi