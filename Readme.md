# AI-Powered Kubernetes Assistant

A Flask-based AI assistant that helps manage and troubleshoot Kubernetes clusters using natural language queries. Powered by Groq's LLM API (llama-3.3-70b-versatile).

## Features

- **Natural Language Interface**: Ask questions in plain English about your cluster
- **Intelligent Tool Calling**: AI automatically executes kubectl commands when needed
- **Session Memory**: Maintains conversation context for follow-up questions
- **Safe Execution**: Whitelist of safe kubectl verbs (get, describe, logs, top, exec, scale, rollout)
- **RBAC Security**: ClusterRole with minimal required permissions
- **Web UI**: Clean, responsive chat interface
- **Production Ready**: Containerized with Helm and Kubernetes manifests

## How It Works

The AI assistant uses Groq's function calling to automatically execute kubectl commands when you ask questions about your cluster. For example:

- "Show me all pods in the default namespace"
- "What's wrong with my deployment?"
- "Scale my app to 3 replicas"
- "Show me logs from the failing pod"

The AI analyzes the results and provides clear, actionable insights.

## Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured with cluster access
- `socat` installed on all nodes (for port-forwarding)
- Groq API key - [Get free key](https://console.groq.com/)

## Quick Start

### Option 1: Terraform Deployment

```bash
cd terraform
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and add your Groq API key

terraform apply
kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80
```

See [terraform/README.md](terraform/README.md) for detailed configuration options.

### Option 2: Helm Deployment (Recommended)

```bash
# Install with your API key
helm install ai-log-tool ./helm-chart \
  --namespace ai-log-tool \
  --create-namespace \
  --set config.groqApiKey="your-groq-api-key-here"

# Access the application
kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80
```

Open http://localhost:8080 in your browser.

**Access from remote machine (e.g., laptop accessing VM):**

If your Kubernetes cluster runs on a VM and you want to access from your laptop:

```bash
# On VM: Port-forward the service
kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80

# On Laptop: SSH tunnel to VM
ssh -L 8080:localhost:8080 root@<vm-ip>
# Example: ssh -L 8080:localhost:8080 root@192.168.1.1
```

Then open http://localhost:8080 on your laptop.

**Customize deployment:**
```bash
# Create custom values file
cat > my-values.yaml <<EOF
replicaCount: 2
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
config:
  groqApiKey: "your-key-here"
EOF

# Install with custom values
helm install ai-log-tool ./helm-chart \
  --namespace ai-log-tool \
  --create-namespace \
  -f my-values.yaml
```

### Option 3: Manual Kubernetes Deployment

```bash
# 1. Create namespace
kubectl create namespace ai-log-tool

# 2. Create secret with your API key
kubectl create secret generic ai-log-tool-secret \
  --from-literal=groq-api-key="your-groq-api-key-here" \
  -n ai-log-tool

# 3. Deploy RBAC, application, and service
kubectl apply -f k8s-manifests/rbac.yaml
kubectl apply -f k8s-manifests/deployment.yaml
kubectl apply -f k8s-manifests/service.yaml

# 4. Access the application
kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80
```

Open http://localhost:8080 in your browser.

**Access from remote machine (e.g., laptop accessing VM):**

If your Kubernetes cluster runs on a VM and you want to access from your laptop:

```bash
# On VM: Port-forward the service
kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80

# On Laptop: SSH tunnel to VM
ssh -L 8080:localhost:8080 root@<vm-ip>
# Example: ssh -L 8080:localhost:8080 root@192.168.1.1
```

Then open http://localhost:8080 on your laptop.

### Option 4: Local Development

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Add your Groq API key to .env
echo "GROQ_API_KEY=your-key-here" > .env

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run the application
python app.py
```

Access at http://localhost:5000

### Option 5: Docker Compose

```bash
# Build and run
docker-compose up --build
```

Access at http://localhost:5000

## Ingress Setup (Optional)

To expose the application via domain name instead of localhost port-forwarding:

### Prerequisites

1. **Install Ingress Controller** (if not already installed):

```bash
# NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Verify installation
kubectl get pods -n ingress-nginx
```

2. **DNS Configuration**: Point your domain to the ingress controller's external IP:

```bash
# Get external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Add DNS A record: ai-log-tool.yourdomain.com -> <EXTERNAL-IP>
```

3. **TLS Certificate** (recommended for HTTPS):

```bash
# Option 1: cert-manager with Let's Encrypt (automated)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Option 2: Manual certificate
kubectl create secret tls ai-log-tool-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n ai-log-tool
```

### Enable Ingress with Helm

Update your Helm values:

```yaml
# my-values.yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # If using cert-manager
  hosts:
    - host: ai-log-tool.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: ai-log-tool-tls
      hosts:
        - ai-log-tool.yourdomain.com
```

Apply the changes:

```bash
helm upgrade ai-log-tool ./helm-chart \
  -n ai-log-tool \
  -f my-values.yaml
```

### Enable Ingress with Kubernetes Manifests

Edit `k8s-manifests/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ai-log-tool
  namespace: ai-log-tool
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # Optional
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - ai-log-tool.yourdomain.com
    secretName: ai-log-tool-tls
  rules:
  - host: ai-log-tool.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ai-log-tool
            port:
              number: 80
```

Apply the ingress:

```bash
kubectl apply -f k8s-manifests/ingress.yaml
```

### Verify Ingress

```bash
# Check ingress status
kubectl get ingress -n ai-log-tool

# Test access
curl -k https://ai-log-tool.yourdomain.com
```

Access your application at: https://ai-log-tool.yourdomain.com

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `GROQ_API_KEY` | Your Groq API key | - | Yes |
| `PORT` | Application port | 5000 | No |
| `FLASK_ENV` | Flask environment | production | No |

### Helm Values

Key configuration options in `helm-chart/values.yaml`:

```yaml
replicaCount: 1
image:
  repository: tihomirvstoyanov/ai-log-tool
  tag: latest
config:
  groqApiKey: ""  # Set via --set or values file
resources:
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## Security

### RBAC Permissions

The application uses a ClusterRole with minimal permissions:

**Read Access:**
- pods, services, nodes, namespaces
- deployments, replicasets, daemonsets, statefulsets
- pod logs and metrics

**Write Access:**
- patch deployments (for scaling)
- create pod/exec (for interactive commands)

### Safe kubectl Verbs

Only these kubectl verbs are allowed:
- `get` - View resources
- `describe` - Detailed resource info
- `logs` - View pod logs
- `top` - Resource usage metrics
- `exec` - Execute commands in pods
- `scale` - Scale deployments
- `rollout` - Manage rollouts

### Best Practices

- ✅ API keys stored as Kubernetes Secrets
- ✅ Container runs as non-root user (UID 1001)
- ✅ Never commit `.env` or `secret.yaml` with real keys
- ✅ Use `.env.example` and `secret.yaml.example` as templates
- ✅ RBAC limits permissions to necessary operations

## Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTP (localhost:8080)
┌──────▼──────────┐
│  Flask Web App  │
│  (Port 5000)    │
├─────────────────┤
│  Groq AI API    │
│  llama-3.3-70b  │
│  Function Call  │
├─────────────────┤
│  kubectl        │
│  (in container) │
└──────┬──────────┘
       │ K8s API
┌──────▼──────────┐
│  Kubernetes     │
│  API Server     │
└─────────────────┘
```

## Usage Examples

Once deployed, try these queries:

```
"Show me all pods in the kube-system namespace"
"What's the status of my deployments?"
"Why is my pod crashing?"
"Show me logs from the nginx pod"
"Scale my app deployment to 3 replicas"
"What nodes are in my cluster?"
"Show me resource usage for all pods"
```

The AI will automatically execute the necessary kubectl commands and explain the results.

## Troubleshooting

### Port-forward fails with "socat not found"

```bash
# Install socat on your nodes
ssh <node-name> "sudo apt-get update && sudo apt-get install -y socat"
```

### Pod not starting

```bash
# Check pod status
kubectl get pods -n ai-log-tool

# View pod details
kubectl describe pod -n ai-log-tool <pod-name>

# Check logs
kubectl logs -n ai-log-tool <pod-name>
```

### kubectl access issues from pod

```bash
# Test kubectl access from inside the pod
kubectl exec -n ai-log-tool <pod-name> -- kubectl get nodes

# Check service account permissions
kubectl auth can-i --list --as=system:serviceaccount:ai-log-tool:ai-log-tool
```

### AI not responding

- Verify Groq API key is correct
- Check pod logs for errors
- Ensure internet connectivity from cluster
- Verify secret is properly mounted

## Project Structure

```
AI-Powered-Log-Tool/
├── app.py                      # Main Flask application
├── version.py                  # Application version
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Container image
├── docker-compose.yml          # Local development
├── .env.example                # Environment template
├── quick-deploy.sh             # Automated deployment script
├── create-self-signed-cert.sh  # TLS certificate generator
├── templates/                  # HTML templates
│   └── index.html
├── static/                     # CSS and JavaScript
│   ├── css/style.css
│   └── js/chat.js
├── k8s-manifests/              # Kubernetes manifests
│   ├── namespace.yaml
│   ├── rbac.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── secret.yaml.example
│   └── deploy.sh               # Manual deployment helper
└── helm-chart/                 # Helm chart
    ├── Chart.yaml
    ├── values.yaml
    ├── values.example.yaml
    └── templates/
```

## Helper Scripts

The project includes several helper scripts to simplify deployment and configuration:

### `quick-deploy.sh`
Automated deployment script with interactive prompts. Supports both Helm and kubectl deployment methods.

```bash
./quick-deploy.sh
```

**Features:**
- Prompts for Groq API key securely
- Auto-detects Helm availability
- Creates namespace and secrets
- Waits for deployment to be ready
- Shows access instructions

### `create-self-signed-cert.sh`
Generates self-signed TLS certificates for ingress setup.

```bash
./create-self-signed-cert.sh ai-log-tool.yourdomain.com
```

**Features:**
- Creates TLS certificate and private key
- Automatically creates Kubernetes secret
- Useful for testing HTTPS without cert-manager
- Cleans up local certificate files

### `k8s-manifests/deploy.sh`
Simple deployment helper for manual kubectl approach.

```bash
cd k8s-manifests
./deploy.sh
```

**Features:**
- Applies manifests in correct order
- Shows deployment status
- Provides access instructions

## Technology Stack

- **Backend**: Flask 3.0.0, Python 3.11
- **AI**: Groq API (llama-3.3-70b-versatile)
- **Container**: Docker with kubectl v1.35.0
- **Orchestration**: Kubernetes 1.20+
- **Web Server**: Gunicorn with 2 workers
- **Frontend**: Vanilla JavaScript, CSS

## Roadmap

Potential improvements:

- [ ] Multi-user authentication (OAuth2/OIDC)
- [ ] Persistent conversation history (Redis/Database)
- [ ] Prometheus metrics and Grafana dashboards
- [ ] Support for multiple clusters
- [ ] Audit logging for all kubectl commands
- [ ] Rate limiting and request throttling
- [ ] WebSocket support for real-time updates
- [ ] Export conversation history
- [ ] Custom kubectl verb whitelist per user
- [ ] Integration with Slack/Teams

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - feel free to use this project for any purpose.

## Support

For issues or questions:
- Open an issue on GitHub
- Check pod logs: `kubectl logs -n ai-log-tool <pod-name>`
- Review RBAC permissions
- Verify API key is valid

## Acknowledgments

- Powered by [Groq](https://groq.com/) for fast LLM inference
- Built with Flask and Kubernetes
- Inspired by the need for easier cluster management
