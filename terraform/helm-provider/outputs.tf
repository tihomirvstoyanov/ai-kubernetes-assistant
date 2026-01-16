output "release_name" {
  description = "Helm release name"
  value       = helm_release.ai_log_tool.name
}

output "namespace" {
  description = "Kubernetes namespace where the application is deployed"
  value       = helm_release.ai_log_tool.namespace
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.ai_log_tool.status
}

output "chart_version" {
  description = "Deployed chart version"
  value       = helm_release.ai_log_tool.version
}

output "port_forward_command" {
  description = "Command to access the application via port-forward"
  value       = "kubectl port-forward -n ${helm_release.ai_log_tool.namespace} svc/${helm_release.ai_log_tool.name} 8080:80"
}

output "ingress_host" {
  description = "Ingress hostname (if enabled)"
  value       = var.enable_ingress ? var.ingress_host : "Ingress not enabled"
}
