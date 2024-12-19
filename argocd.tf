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
  depends_on = [
    helm_release.nfs_server
  ]
}

resource "kubernetes_namespace" "database" {
  metadata {
    name = "database"
  }
  depends_on = [
    helm_release.nfs_server
  ]
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

# Esperar a que los servicios adicionales estén listos
resource "time_sleep" "wait_for_services" {
  depends_on = [
    helm_release.nfs_server,
    kubernetes_secret.mariadb_credentials
  ]

  create_duration = "30s"
}

resource "kubernetes_manifest" "argocd_application_mariadb" {
  depends_on = [
    time_sleep.wait_for_services,
    kubernetes_secret.mariadb_credentials
  ]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "mariadb"
      namespace = "argocd"
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
    helm_release.nfs_server,
    kubernetes_secret.mariadb_credentials
  ]

  create_duration = "90s"
}

resource "kubernetes_manifest" "argocd_application_erpnext" {
  depends_on = [
    time_sleep.wait_for_services_erpnext,
    kubernetes_manifest.argocd_application_mariadb,
    kubernetes_namespace.erpnext
  ]

  manifest = yamldecode(file("app.yaml"))

}