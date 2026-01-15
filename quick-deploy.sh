#!/bin/bash
# Quick deployment script for AI-Powered Kubernetes Log Tool

set -e

echo "==================================="
echo "AI-Powered Kubernetes Log Tool"
echo "Quick Deployment Script"
echo "==================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "⚠️  Helm not found. Will use kubectl manifests instead."
    USE_HELM=false
else
    USE_HELM=true
fi

# Prompt for API key
echo "Please enter your Groq API key (get from https://console.groq.com/):"
read -s GROQ_API_KEY

if [ -z "$GROQ_API_KEY" ]; then
    echo "❌ API key is required"
    exit 1
fi

echo ""
echo "Creating namespace..."
kubectl create namespace ai-log-tool --dry-run=client -o yaml | kubectl apply -f -

if [ "$USE_HELM" = true ]; then
    echo ""
    echo "Deploying with Helm..."
    helm upgrade --install ai-log-tool ./helm-chart \
        --namespace ai-log-tool \
        --set config.groqApiKey="$GROQ_API_KEY" \
        --wait
else
    echo ""
    echo "Deploying with kubectl..."
    
    # Create secret
    kubectl create secret generic ai-log-tool-secret \
        --from-literal=groq-api-key="$GROQ_API_KEY" \
        -n ai-log-tool \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply manifests
    kubectl apply -f k8s-manifests/rbac.yaml
    kubectl apply -f k8s-manifests/deployment.yaml
    kubectl apply -f k8s-manifests/service.yaml
    
    echo "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=120s \
        deployment/ai-log-tool -n ai-log-tool
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "To access the application:"
echo "  kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80 --address 0.0.0.0"
echo ""
echo "Then open: http://localhost:8080"
echo ""
echo "To check status:"
echo "  kubectl get pods -n ai-log-tool"
echo "  kubectl logs -n ai-log-tool -l app=ai-log-tool"
echo ""
