terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {}

resource "kubernetes_namespace" "ai_log_tool" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "ai_log_tool" {
  name       = var.release_name
  chart      = var.chart_path
  namespace  = var.namespace
  create_namespace = false

  values = var.values_file != "" ? [file(var.values_file)] : []

  set_sensitive {
    name  = "config.groqApiKey"
    value = var.groq_api_key
  }

  set {
    name  = "replicaCount"
    value = var.replicas
  }

  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "resources.limits.cpu"
    value = var.cpu_limit
  }

  set {
    name  = "resources.limits.memory"
    value = var.memory_limit
  }

  set {
    name  = "resources.requests.cpu"
    value = var.cpu_request
  }

  set {
    name  = "resources.requests.memory"
    value = var.memory_request
  }

  set {
    name  = "ingress.enabled"
    value = var.enable_ingress
  }

  dynamic "set" {
    for_each = var.enable_ingress ? [1] : []
    content {
      name  = "ingress.className"
      value = var.ingress_class
    }
  }

  dynamic "set" {
    for_each = var.enable_ingress ? [1] : []
    content {
      name  = "ingress.hosts[0].host"
      value = var.ingress_host
    }
  }

  dynamic "set" {
    for_each = var.enable_ingress && var.ingress_tls_enabled ? [1] : []
    content {
      name  = "ingress.tls[0].secretName"
      value = var.ingress_tls_secret
    }
  }

  dynamic "set" {
    for_each = var.enable_ingress && var.ingress_tls_enabled ? [1] : []
    content {
      name  = "ingress.tls[0].hosts[0]"
      value = var.ingress_host
    }
  }

  dynamic "set" {
    for_each = var.ingress_annotations
    content {
      name  = "ingress.annotations.${replace(set.key, ".", "\\.")}"
      value = set.value
    }
  }

  depends_on = [kubernetes_namespace.ai_log_tool]
}
