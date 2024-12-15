resource "kubernetes_namespace" "argocd" {  
  metadata {
    name = "argocd"
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
  create_namespace = true

  values = [
    <<-EOF
    server:
      extraArgs:
        - --insecure
    EOF
  ]
}


# Definir una aplicación de ArgoCD para desplegar "Hello World"
resource "kubernetes_manifest" "erpnext" {
  depends_on = [helm_release.argocd]
  
  manifest = yamldecode(file("${path.module}/app.yaml"))
}