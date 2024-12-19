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

# Esperar a que los servicios adicionales estén listos
resource "time_sleep" "wait_for_services" {
  depends_on = [
    helm_release.nfs_server,
    kubernetes_secret.mariadb_credentials
  ]

  create_duration = "30s"
}

data "template_file" "mariadb_manifest" {
  template = file("mariadb.yaml")
  vars = {
    mariadb_credentials = kubernetes_secret.mariadb_credentials.metadata[0].name
  }
}

resource "kubernetes_manifest" "argocd_application_mariadb" {
  depends_on = [
    time_sleep.wait_for_services,
    kubernetes_secret.mariadb_credentials,
    kubernetes_namespace.database
  ]

  manifest = data.template_file.mariadb_manifest.rendered
}

resource "time_sleep" "wait_for_services_erpnext" {
  depends_on = [
    helm_release.nfs_server,
    kubernetes_secret.mariadb_credentials
  ]

  create_duration = "90s"
}

/* resource "kubernetes_manifest" "argocd_application_erpnext" {
  depends_on = [
    time_sleep.wait_for_services_erpnext,
    kubernetes_manifest.argocd_application_mariadb,
    kubernetes_namespace.erpnext
  ]

  manifest = yamldecode(file("app.yaml"))

}
 */