#!/bin/bash

# =============================================================================
# Deploy and Test Wil's Playground Application
# =============================================================================
# This script deploys the playground application and verifies it's working
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Path to manifests directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/manifests"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        log_info "Make sure you have a k3d cluster running: k3d cluster list"
        exit 1
    fi
    
    log_success "kubectl is available and cluster is accessible"
}

# Deploy the application
deploy_app() {
    log_step "Deploying playground application..."
    
    # Apply namespace
    log_info "Creating dev namespace..."
    kubectl apply -f "$MANIFESTS_DIR/namespace.yaml" || {
        log_warning "Namespace might already exist, continuing..."
    }
    
    # Apply deployment
    log_info "Applying deployment..."
    kubectl apply -f "$MANIFESTS_DIR/deployment.yaml"
    
    # Apply service
    log_info "Applying service..."
    kubectl apply -f "$MANIFESTS_DIR/service.yaml"
    
    log_success "Manifests applied successfully"
}

# Wait for deployment to be ready
wait_for_deployment() {
    log_step "Waiting for deployment to be ready..."
    
    local max_attempts=60
    local attempt=0
    local namespace="dev"
    local deployment="playground"
    
    while [ $attempt -lt $max_attempts ]; do
        if kubectl wait --for=condition=available --timeout=60s deployment/$deployment -n $namespace 2>/dev/null; then
            log_success "Deployment is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        if [ $((attempt % 5)) -eq 0 ]; then
            log_info "Still waiting... (attempt $attempt/$max_attempts)"
            # Show pod status
            kubectl get pods -n $namespace -l app=playground 2>/dev/null || true
        fi
        
        sleep 2
    done
    
    log_error "Deployment did not become ready within expected time"
    log_info "Checking pod status..."
    kubectl get pods -n $namespace -l app=playground || true
    kubectl describe pod -n $namespace -l app=playground | tail -20 || true
    exit 1
}

# Wait for service to be available
wait_for_service() {
    log_step "Waiting for service to be ready..."
    
    local max_attempts=30
    local attempt=0
    local namespace="dev"
    local service="playground"
    
    while [ $attempt -lt $max_attempts ]; do
        if kubectl get svc $service -n $namespace &>/dev/null; then
            local external_ip=$(kubectl get svc $service -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
            # For k3d LoadBalancer, the IP might be empty, but the service is still accessible via port mapping
            if [ -n "$external_ip" ] || kubectl get svc $service -n $namespace -o jsonpath='{.spec.type}' | grep -q "LoadBalancer"; then
                log_success "Service is ready"
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log_warning "Service check timed out, but continuing..."
}

# Test the application
test_app() {
    log_step "Testing application..."
    
    local url="http://localhost:8888"
    local max_attempts=30
    local attempt=0
    local response=""
    
    log_info "Attempting to connect to $url..."
    
    while [ $attempt -lt $max_attempts ]; do
        # Try to get response
        response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null || echo "FAILED")
        http_code=$(echo "$response" | tail -1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ] && [ -n "$body" ]; then
            log_success "Application responded successfully!"
            echo ""
            echo "Response: $body"
            echo ""
            
            # Check if response matches expected format
            if echo "$body" | grep -q '"status":"ok"'; then
                log_success "Response format is correct"
                
                # Extract version
                version=$(echo "$body" | grep -o '"message": "[^"]*"' | cut -d'"' -f4 || echo "unknown")
                log_info "Application version: $version"
                
                # Verify expected version based on deployment
                current_image=$(kubectl get deployment playground -n dev -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
                expected_version=$(echo "$current_image" | grep -o 'v[0-9]' || echo "v1")
                
                if [ "$version" = "$expected_version" ]; then
                    log_success "Version matches deployment: $expected_version"
                else
                    log_warning "Version mismatch: got $version, expected $expected_version"
                fi
            else
                log_warning "Response format might be unexpected"
            fi
            
            return 0
        fi
        
        attempt=$((attempt + 1))
        if [ $((attempt % 5)) -eq 0 ]; then
            log_info "Still waiting for application to respond... (attempt $attempt/$max_attempts)"
            log_info "Checking if service is accessible..."
            log_info "Port 8888 might not be mapped yet"
        fi
        
        sleep 2
    done
    
    log_error "Application did not respond within expected time"
    log_info "Troubleshooting information:"
    echo ""
    echo "=== Service Status ==="
    kubectl get svc playground -n dev || true
    echo ""
    echo "=== Pod Status ==="
    kubectl get pods -n dev -l app=playground || true
    echo ""
    echo "=== Port Mapping Check ==="
    k3d cluster list 2>/dev/null || echo "Not using k3d or k3d not available"
    echo ""
    echo "=== Manual Test ==="
    echo "Try: curl http://localhost:8888/"
    exit 1
}

# Show status
show_status() {
    log_step "Application Status:"
    echo ""
    echo "=== Namespace ==="
    kubectl get ns dev 2>/dev/null || echo "Namespace 'dev' not found"
    echo ""
    echo "=== Deployment ==="
    kubectl get deployment playground -n dev 2>/dev/null || echo "Deployment 'playground' not found"
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n dev -l app=playground 2>/dev/null || echo "No pods found"
    echo ""
    echo "=== Service ==="
    kubectl get svc playground -n dev 2>/dev/null || echo "Service 'playground' not found"
    echo ""
    echo "=== Service Details ==="
    kubectl get svc playground -n dev -o wide 2>/dev/null || true
    echo ""
    echo "=== Access Information ==="
    echo "URL: http://localhost:8888"
    echo "Expected response: {\"status\":\"ok\", \"message\": \"v1\"}"
    echo ""
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     Deploy and Test Wil's Playground Application           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Validate environment
    check_kubectl
    
    # Deploy
    deploy_app
    
    # Wait for readiness
    wait_for_deployment
    wait_for_service
    
    # Show initial status
    show_status
    
    # Test
    test_app
    
    echo ""
    log_success "✅ Deployment and testing completed successfully!"
    echo ""
    log_info "You can now access the application at: http://localhost:8888"
    log_info "To check status: kubectl get pods -n dev"
    log_info "To check logs: kubectl logs -n dev -l app=playground"
}

# Run main function
main "$@"

