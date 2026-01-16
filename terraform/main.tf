terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

resource "kubernetes_namespace" "ai_log_tool" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "ai_log_tool" {
  metadata {
    name      = "ai-log-tool-secret"
    namespace = kubernetes_namespace.ai_log_tool.metadata[0].name
  }

  data = {
    groq-api-key = var.groq_api_key
  }

  type = "Opaque"
}

resource "kubernetes_service_account" "ai_log_tool" {
  metadata {
    name      = "ai-log-tool"
    namespace = kubernetes_namespace.ai_log_tool.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "ai_log_tool" {
  metadata {
    name = "ai-log-tool"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "nodes", "namespaces", "events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "ai_log_tool" {
  metadata {
    name = "ai-log-tool"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ai_log_tool.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ai_log_tool.metadata[0].name
    namespace = kubernetes_namespace.ai_log_tool.metadata[0].name
  }
}

resource "kubernetes_deployment" "ai_log_tool" {
  metadata {
    name      = "ai-log-tool"
    namespace = kubernetes_namespace.ai_log_tool.metadata[0].name
    labels = {
      app = "ai-log-tool"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "ai-log-tool"
      }
    }

    template {
      metadata {
        labels = {
          app = "ai-log-tool"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.ai_log_tool.metadata[0].name

        security_context {
          fs_group = 1001
        }

        container {
          name              = "ai-log-tool"
          image             = var.image
          image_pull_policy = "Always"

          port {
            container_port = 5000
            name           = "http"
          }

          env {
            name = "GROQ_API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.ai_log_tool.metadata[0].name
                key  = "groq-api-key"
              }
            }
          }

          env {
            name  = "PORT"
            value = "5000"
          }

          env {
            name  = "FLASK_ENV"
            value = "production"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          resources {
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }

          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 1001
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ai_log_tool" {
  metadata {
    name      = "ai-log-tool"
    namespace = kubernetes_namespace.ai_log_tool.metadata[0].name
    labels = {
      app = "ai-log-tool"
    }
  }

  spec {
    selector = {
      app = "ai-log-tool"
    }

    port {
      port        = 80
      target_port = 5000
      protocol    = "TCP"
      name        = "http"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "ai_log_tool" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "ai-log-tool"
    namespace = kubernetes_namespace.ai_log_tool.metadata[0].name
    annotations = merge(
      {
        "kubernetes.io/ingress.class" = var.ingress_class
      },
      var.ingress_annotations
    )
  }

  spec {
    dynamic "tls" {
      for_each = var.ingress_tls_enabled ? [1] : []
      content {
        hosts       = [var.ingress_host]
        secret_name = var.ingress_tls_secret
      }
    }

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.ai_log_tool.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
