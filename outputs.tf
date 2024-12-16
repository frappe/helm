# outputs.tf

output "argocd_installation" {
  description = "Información sobre la instalación de ArgoCD"
  value = {
    namespace = helm_release.argocd.namespace
    release   = helm_release.argocd.name
  }
}