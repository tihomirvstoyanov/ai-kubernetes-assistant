# Terraform Deployment

This directory contains Terraform configurations for deploying the AI-Powered Kubernetes Assistant to a Kubernetes cluster.

## Two Approaches Available

### 1. Native Kubernetes Resources (Current Directory)
Deploy using Terraform's Kubernetes provider with native resources (Deployment, Service, etc.).

**Best for:** Full control over Kubernetes resources, custom configurations

[See instructions below](#quick-start)

### 2. Helm Provider (helm-provider/ subdirectory)
Deploy using Terraform's Helm provider to install the existing Helm chart.

**Best for:** Leveraging the maintained Helm chart, simpler configuration

[See helm-provider/README.md](helm-provider/README.md)

---

## Prerequisites

- Terraform >= 1.0
- kubectl configured with cluster access
- Groq API key - [Get free key](https://console.groq.com/)

## Quick Start (Native Kubernetes Resources)

1. **Initialize Terraform:**
```bash
cd terraform
terraform init
```

2. **Create your variables file:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and add your Groq API key
```

3. **Review the plan:**
```bash
terraform plan
```

4. **Deploy:**
```bash
terraform apply
```

5. **Access the application:**
```bash
# Use the output command
terraform output -raw port_forward_command | bash
```

Then open http://localhost:8080 in your browser.

## Configuration

### Required Variables

- `groq_api_key` - Your Groq API key (sensitive)

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `kubeconfig_path` | Path to kubeconfig file | `~/.kube/config` |
| `namespace` | Kubernetes namespace | `ai-log-tool` |
| `image` | Docker image | `tihomirvstoyanov/ai-log-tool:latest` |
| `replicas` | Number of replicas | `1` |
| `cpu_limit` | CPU limit | `500m` |
| `memory_limit` | Memory limit | `512Mi` |
| `cpu_request` | CPU request | `100m` |
| `memory_request` | Memory request | `128Mi` |

### Ingress Configuration

To enable ingress:

```hcl
enable_ingress = true
ingress_host = "ai-log-tool.yourdomain.com"
ingress_class = "nginx"
ingress_tls_enabled = true
ingress_tls_secret = "ai-log-tool-tls"
ingress_annotations = {
  "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
}
```

## Examples

### Basic Deployment

```bash
terraform apply -var="groq_api_key=your-key-here"
```

### Custom Configuration

```bash
terraform apply \
  -var="groq_api_key=your-key-here" \
  -var="replicas=2" \
  -var="memory_limit=1Gi"
```

### With Ingress

```bash
terraform apply \
  -var="groq_api_key=your-key-here" \
  -var="enable_ingress=true" \
  -var="ingress_host=ai-log-tool.example.com"
```

## Outputs

After deployment, Terraform provides:

- `namespace` - Deployed namespace
- `service_name` - Service name
- `deployment_name` - Deployment name
- `port_forward_command` - Command to access via port-forward
- `ingress_host` - Ingress hostname (if enabled)

View outputs:
```bash
terraform output
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Notes

- API key is stored as a Kubernetes Secret
- RBAC permissions are automatically configured
- The deployment uses the same security settings as Helm/kubectl methods
- State file contains sensitive data - store securely or use remote backend
