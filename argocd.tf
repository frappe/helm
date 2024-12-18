resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = "argocd"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  version    = "5.51.6"

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

resource "kubernetes_service" "argogrpc" {
  metadata {
    name      = "argogrpc"
    namespace = kubernetes_namespace.argocd.metadata.0.name
    labels = {
      "app" : "argogrpc"
    }
    annotations = {
      "alb.ingress.kubernetes.io/backend-protocol-version" : "GRPC"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
    session_affinity = "None"
    port {
      port        = 443
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_ingress_v1" "argocd-ingress" {
  metadata {
    name      = "argocd-server-ingress"
    namespace = kubernetes_namespace.argocd.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.class" : "alb"
      "alb.ingress.kubernetes.io/load-balancer-name" : var.alb_name
      "alb.ingress.kubernetes.io/scheme" : "internet-facing"
      "alb.ingress.kubernetes.io/backend-protocol" : "HTTPS"
      "alb.ingress.kubernetes.io/healthcheck-path" : "/healthz"
      "alb.ingress.kubernetes.io/target-type" : "ip"
      # Use this annotation (which must match a service name) to route traffic to HTTP2 backends.
      "alb.ingress.kubernetes.io/conditions.argogrpc" : "[{\"field\":\"http-header\",\"httpHeaderConfig\":{\"httpHeaderName\": \"Content-Type\", \"values\":[\"application/grpc\"]}}]"
      "alb.ingress.kubernetes.io/listen-ports" : "[{\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/certificate-arn" : "arn:aws:acm:eu-west-1:659192515497:certificate/e4958d34-7ce7-45d6-84e4-accd35b5edb8"
      "alb.ingress.kubernetes.io/group.name" : "dev"
    }
  }

  spec {
    rule {
      host = "argocd.cluster.local"
      http {
        path {
          backend {
            service {
              name = "argogrpc"
              port {
                number = 443
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }

        path {
          backend {
            service {
              name = "argocd-server"
              port {
                number = 443
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
    tls {
      hosts = ["argocd.cluster.local"]
    }
  }
}

#https://artifacthub.io/packages/helm/argo/argocd-apps
resource "helm_release" "argocd-apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  version    = "1.4.1"


  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.argocd
  ]

  values = [
    file("install.yaml")
  ]
}

# Resource below are used to wait for ALB interfaces will be published
resource "time_sleep" "wait_60_seconds" {
  depends_on = [helm_release.argocd-apps]

  create_duration = "60s"
}

resource "kubernetes_namespace" "nfs" {
  metadata {
    name = "nfs"
  }
}

resource "helm_release" "nfs_server" {
  name       = "in-cluster"
  repository = "https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner"
  chart      = "nfs-server-provisioner"
  namespace  = kubernetes_namespace.nfs.metadata[0].name

  # Ajustar valores con 'set' para emular --set en helm
  set {
    name  = "storageClass.mountOptions[0]"
    value = "vers=4.1"
  }

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.size"
    value = "8Gi"
  }

  depends_on = [
    kubernetes_namespace.nfs
  ]
}

resource "kubernetes_namespace" "erpnext" {
  metadata {
    name = "erpnext"
  }
}

/* resource "helm_release" "frappe_erpnext" {
  name       = "frappe-bench"
  namespace  = kubernetes_namespace.erpnext.metadata[0].name
  repository = "https://helm.erpnext.com"
  chart      = "erpnext"

  # Agregar configuración para forzar la limpieza y recreación
  set {
    name  = "persistence.worker.storageClass"
    value = "nfs"
  }

  set {
    name  = "persistence.worker.annotations.\"helm.sh/resource-policy\""
    value = "keep"
  }

  set {
    name  = "persistence.worker.accessMode"
    value = "ReadWriteOnce"
  }

  # Forzar la recreación del release si existe
  replace = true
  force_update = true
  cleanup_on_fail = true
  
  depends_on = [
    helm_release.nfs_server,
    kubernetes_namespace.erpnext,
    kubernetes_manifest.argocd_application_mariadb
  ]
} */

resource "kubernetes_namespace" "database" {
  metadata {
    name = "database"
  }
}

resource "kubernetes_secret" "mariadb_credentials" {
  metadata {
    name      = "mariadb-credentials"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  data = {
    "mariadb-root-password"        = "SMNGg8X66YhT7UfW"
    "mariadb-replication-password" = "SMNGg8X66YhT7UfW"
    "mariadb-password"             = "SMNGg8X66YhT7UfW"
  }

  # Asegura que el secreto se cree después del namespace
  depends_on = [
    kubernetes_namespace.database
  ]
}

# Esperar a que ArgoCD esté completamente listo
resource "time_sleep" "wait_for_argocd" {
  depends_on = [helm_release.argocd]

  create_duration = "90s"
}

# Esperar a que los servicios adicionales estén listos
resource "time_sleep" "wait_for_services" {
  depends_on = [
    helm_release.argocd-apps,
    helm_release.nfs_server,
    kubernetes_secret.mariadb_credentials,
    time_sleep.wait_for_argocd
  ]

  create_duration = "30s"
}

resource "kubernetes_manifest" "argocd_application_mariadb" {
  depends_on = [
    time_sleep.wait_for_services
  ]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "mariadb"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://charts.bitnami.com/bitnami"
        chart          = "mariadb"
        targetRevision = "16.3.2"
        helm = {
          releaseName = "mariadb"
          values = yamlencode({
            architecture = "standalone"
            auth = {
              database       = "geekcity"
              username      = "ben.wangz"
              existingSecret = "mariadb-credentials"
            }
            primary = {
              extraFlags = "--character-set-server=utf8mb4 --collation-server=utf8mb4_bin"
              persistence = {
                enabled = false
              }
            }
            secondary = {
              replicaCount = 1
              persistence = {
                enabled = false
              }
            }
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.database.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune       = true
          selfHeal    = true
          allowEmpty  = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "ServerSideApply=true"
        ]
      }
    }
  }
}

resource "time_sleep" "wait_for_services_erpnext" {
  depends_on = [
    helm_release.argocd-apps,
    helm_release.nfs_server,
    kubernetes_secret.mariadb_credentials,
    time_sleep.wait_for_argocd,
  ]

  create_duration = "90s"
}

resource "kubernetes_manifest" "argocd_application_erpnext" {
  depends_on = [
    time_sleep.wait_for_services_erpnext
  ]

  manifest = yamldecode(file("app.yaml"))

}
