# Terraform with Helm Provider

This directory contains Terraform configuration that uses the **Helm provider** to deploy the existing Helm chart. This approach is ideal if you want Terraform workflow but prefer to use the maintained Helm chart.

## Why Use This Approach?

- **Leverage existing Helm chart** - No need to maintain duplicate Kubernetes resources
- **Terraform state management** - Track Helm releases in Terraform state
- **Infrastructure as Code** - Manage Helm releases alongside other Terraform resources
- **Helm chart updates** - Automatically use latest chart improvements

## Prerequisites

- Terraform >= 1.0
- kubectl configured with cluster access
- Groq API key - [Get free key](https://console.groq.com/)

## Quick Start

1. **Initialize Terraform:**
```bash
cd terraform/helm-provider
terraform init
```

2. **Create your variables file:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and add your Groq API key
```

3. **Deploy:**
```bash
terraform apply
```

4. **Access the application:**
```bash
kubectl port-forward -n ai-log-tool svc/ai-log-tool 8080:80
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
| `release_name` | Helm release name | `ai-log-tool` |
| `chart_path` | Path to Helm chart | `../../helm-chart` |
| `values_file` | Custom values.yaml path | `""` |
| `replicas` | Number of replicas | `1` |
| `image_repository` | Docker image repository | `tihomirvstoyanov/ai-log-tool` |
| `image_tag` | Docker image tag | `latest` |

### Using Custom Values File

You can provide a custom `values.yaml` file:

```hcl
values_file = "my-custom-values.yaml"
```

Or override specific values via variables:

```hcl
replicas = 2
memory_limit = "1Gi"
enable_ingress = true
```

## Examples

### Basic Deployment

```bash
terraform apply -var="groq_api_key=your-key-here"
```

### With Custom Values File

```bash
# Create custom values
cat > my-values.yaml <<EOF
replicaCount: 2
resources:
  limits:
    memory: "1Gi"
EOF

# Deploy with custom values
terraform apply \
  -var="groq_api_key=your-key-here" \
  -var="values_file=my-values.yaml"
```

### With Ingress

```bash
terraform apply \
  -var="groq_api_key=your-key-here" \
  -var="enable_ingress=true" \
  -var="ingress_host=ai-log-tool.example.com" \
  -var="ingress_tls_enabled=true"
```

## Outputs

After deployment, Terraform provides:

- `release_name` - Helm release name
- `namespace` - Deployed namespace
- `release_status` - Helm release status
- `chart_version` - Deployed chart version
- `port_forward_command` - Command to access via port-forward
- `ingress_host` - Ingress hostname (if enabled)

View outputs:
```bash
terraform output
```

## Helm Commands

Since this uses Helm under the hood, you can also use Helm CLI:

```bash
# List releases
helm list -n ai-log-tool

# Get release status
helm status ai-log-tool -n ai-log-tool

# View values
helm get values ai-log-tool -n ai-log-tool

# Upgrade manually (if needed)
helm upgrade ai-log-tool ../../helm-chart -n ai-log-tool
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

This will uninstall the Helm release and optionally delete the namespace.

## Comparison: Helm Provider vs Native Kubernetes

| Feature | Helm Provider | Native Kubernetes |
|---------|---------------|-------------------|
| Chart updates | Automatic | Manual sync needed |
| Complexity | Lower | Higher |
| Flexibility | Medium | High |
| Maintenance | Easier | More work |
| Best for | Using existing charts | Custom resources |

## Notes

- The Helm chart is located at `../../helm-chart` (relative path)
- Terraform manages the Helm release lifecycle
- Chart values can be overridden via Terraform variables
- State file contains sensitive data - store securely
- Compatible with all Helm chart features
