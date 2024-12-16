resource "kubernetes_namespace" "argocd" {  
  metadata {
    name = var.argocd_namespace
  }
}

# Instalar ArgoCD usando el chart oficial de Helm
resource "helm_release" "argocd" {
  provider = helm

  name             = var.argocd_namespace
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = false
  
  # Asegúrate de instalar los CRDs
  skip_crds = false

  # Agregar estas opciones para manejar mejor la instalación
  force_update     = true
  cleanup_on_fail  = true
  replace          = true
  atomic           = true  # Asegura rollback en caso de fallo

  values = [
    <<-EOF
    server:
      extraArgs:
        - --insecure
    EOF
  ]
}

# Crear la aplicación usando kubectl_manifest
data "kubernetes_service" "argocd_server" {
 metadata {
   name      = "argocd-server"
   namespace = helm_release.argocd.namespace
 }
}

resource "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd-ingress"
    namespace = var.argocd_namespace
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    }
  }

  spec {
    ingress_class_name = "nginx-custom"
    rule {
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.ingress_nginx]
}

# Install NGINX Ingress Controller
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  # Add these values to handle the existing IngressClass
  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx-custom"
  }

  set {
    name  = "controller.ingressClassResource.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  # Optional: Force creation/replacement
  force_update  = true
  replace       = true

  depends_on = [kubernetes_namespace.argocd]
}