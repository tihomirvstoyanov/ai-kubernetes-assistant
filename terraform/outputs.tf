output "namespace" {
  description = "Kubernetes namespace where the application is deployed"
  value       = kubernetes_namespace.ai_log_tool.metadata[0].name
}

output "service_name" {
  description = "Kubernetes service name"
  value       = kubernetes_service.ai_log_tool.metadata[0].name
}

output "deployment_name" {
  description = "Kubernetes deployment name"
  value       = kubernetes_deployment.ai_log_tool.metadata[0].name
}

output "port_forward_command" {
  description = "Command to access the application via port-forward"
  value       = "kubectl port-forward -n ${kubernetes_namespace.ai_log_tool.metadata[0].name} svc/${kubernetes_service.ai_log_tool.metadata[0].name} 8080:80"
}

output "ingress_host" {
  description = "Ingress hostname (if enabled)"
  value       = var.enable_ingress ? var.ingress_host : "Ingress not enabled"
}
