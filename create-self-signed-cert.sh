#!/bin/bash

# Script to create self-signed TLS certificate for AI Log Tool

if [ -z "$1" ]; then
    echo "Usage: $0 <your-dns-name>"
    echo "Example: $0 ec2-54-123-45-67.compute-1.amazonaws.com"
    exit 1
fi

DNS_NAME=$1
NAMESPACE="ai-log-tool"

echo "Creating self-signed certificate for: $DNS_NAME"

# Generate private key
openssl genrsa -out tls.key 2048

# Generate certificate
openssl req -new -x509 -key tls.key -out tls.crt -days 365 -subj "/CN=$DNS_NAME"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create Kubernetes TLS secret
kubectl create secret tls ai-log-tool-tls-self-signed \
  --cert=tls.crt \
  --key=tls.key \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

# Clean up local files
rm tls.key tls.crt

echo ""
echo "✅ Self-signed certificate created successfully!"
echo ""
echo "Next steps:"
echo "1. Update your ingress file with DNS name: $DNS_NAME"
echo "2. Deploy the application"
echo "3. Access via: https://$DNS_NAME"
echo ""
echo "Note: Your browser will show a security warning (expected for self-signed certs)"
echo "      Click 'Advanced' -> 'Proceed to site' to continue"
