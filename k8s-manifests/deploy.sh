#!/bin/bash

# Deploy AI Log Tool to Kubernetes

echo "Deploying AI Log Tool to Kubernetes..."

# Apply manifests in order
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f rbac.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Optional: Apply ingress (uncomment if needed)
# kubectl apply -f ingress.yaml

echo "Deployment complete!"
echo ""
echo "To check status:"
echo "kubectl get pods -n ai-log-tool"
echo ""
echo "To access the service:"
echo "kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80"
echo "Then open: http://localhost:8080"
