# outputs.tf

output "argocd_installation" {
  description = "Información sobre la instalación de ArgoCD"
  value = {
    namespace = helm_release.argocd.namespace
    release   = helm_release.argocd.name
  }
}

output "argocd_server" {
  description = "URL de acceso a ArgoCD (usa port-forward para acceder localmente)"
  value       = "http://localhost:8080"
}
