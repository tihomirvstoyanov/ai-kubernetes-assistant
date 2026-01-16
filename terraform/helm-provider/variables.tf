variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "ai-log-tool"
}

variable "create_namespace" {
  description = "Create namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "ai-log-tool"
}

variable "chart_path" {
  description = "Path to Helm chart (relative or absolute)"
  type        = string
  default     = "../../helm-chart"
}

variable "values_file" {
  description = "Path to custom values.yaml file (optional)"
  type        = string
  default     = ""
}

variable "groq_api_key" {
  description = "Groq API key for AI functionality"
  type        = string
  sensitive   = true
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "tihomirvstoyanov/ai-log-tool"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 1
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "128Mi"
}

variable "enable_ingress" {
  description = "Enable ingress resource"
  type        = bool
  default     = false
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Ingress hostname"
  type        = string
  default     = "ai-log-tool.example.com"
}

variable "ingress_tls_enabled" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

variable "ingress_tls_secret" {
  description = "TLS secret name for ingress"
  type        = string
  default     = "ai-log-tool-tls"
}

variable "ingress_annotations" {
  description = "Additional annotations for ingress"
  type        = map(string)
  default     = {}
}
