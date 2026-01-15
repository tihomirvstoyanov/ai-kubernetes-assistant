# GitHub Actions Setup

## Required Secrets

Configure these secrets in your GitHub repository settings:

### Docker Hub
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Docker Hub access token

### Kubernetes
- `KUBE_CONFIG`: Base64 encoded kubeconfig file for your cluster
- `GROQ_API_KEY`: Your Groq API key for deployments

### Optional
- `SLACK_WEBHOOK`: For deployment notifications

## Workflows

### 1. docker-build.yml
- **Triggers**: Push to main/develop, PRs, releases
- **Actions**: Build, test, and push Docker images
- **Tags**: Automatic versioning with timestamps and git SHA

### 2. deploy.yml
- **Triggers**: Successful build, manual dispatch
- **Actions**: Deploy to Kubernetes using Helm
- **Environments**: Staging and production support

### 3. release.yml
- **Triggers**: Git tags (v*)
- **Actions**: Create GitHub releases, package Helm charts

### 4. security.yml
- **Triggers**: Push, PR, weekly schedule
- **Actions**: Vulnerability scanning with Trivy

## Setup Instructions

1. **Create Docker Hub Token**:
   ```bash
   # Go to Docker Hub → Account Settings → Security → New Access Token
   ```

2. **Generate Kubeconfig**:
   ```bash
   # Encode your kubeconfig
   cat ~/.kube/config | base64 -w 0
   ```

3. **Add Secrets to GitHub**:
   - Go to repository Settings → Secrets and variables → Actions
   - Add all required secrets

4. **Test Deployment**:
   ```bash
   # Push to main branch or create a tag
   git tag v1.0.0
   git push origin v1.0.0
   ```

## Automatic Versioning

- **Branch pushes**: `main`, `develop`, `YYYYMMDD-HHmmss-sha`
- **Tags**: `v1.0.0`, `v1.0`, `latest`
- **PRs**: `pr-123`

## Multi-Environment Support

- **Staging**: Deploys automatically from main branch
- **Production**: Manual deployment via workflow dispatch
- **Namespaces**: `ai-log-tool-staging`, `ai-log-tool-production`
