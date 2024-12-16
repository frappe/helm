# Instalar ArgoCD usando el chart oficial de Helm
resource "helm_release" "argocd" {
  provider = helm

  name             = var.argocd_namespace
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true
  
  # Ignorar si ya existe
  replace          = true
  force_update     = true
  cleanup_on_fail  = true
  atomic           = true

  # Asegúrate de instalar los CRDs
  skip_crds = false

  values = [
    <<-EOF
    server:
      extraArgs:
        - --insecure
    EOF
  ]

  lifecycle {
    ignore_changes = all
  }
}

# Crear la aplicación usando kubectl_manifest
data "kubernetes_service" "argocd_server" {
 metadata {
   name      = "argocd-server"
   namespace = helm_release.argocd.namespace
 }
 depends_on = [helm_release.argocd]
}

resource "kubernetes_ingress_v1" "argocd-ingress" {
  metadata {
    name      = "argocd-ingress"
    namespace = var.argocd_namespace
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/proxy-buffer-size" = "128k"
      "nginx.ingress.kubernetes.io/proxy-buffers-number" = "4"
    }
  }

  spec {
    ingress_class_name = "nginx-custom"
    rule {
      host = "argocd.cluster.local"
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

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.argocd
  ]
}

# Install NGINX Ingress Controller
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  create_namespace = true

  # Agregar estas opciones para mejor manejo de actualizaciones
  atomic          = true
  cleanup_on_fail = true
  force_update    = true
  replace         = true
  reset_values    = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

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

  set {
    name  = "controller.config.ssl-protocols"
    value = "TLSv1.2 TLSv1.3"
  }

  timeout = 600
  wait    = true

  lifecycle {
    create_before_destroy = true
  }
}