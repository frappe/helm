# outputs.tf

output "argocd_installation" {
  description = "Información sobre la instalación de ArgoCD"
  value = {
    namespace = helm_release.argocd.namespace
    release   = helm_release.argocd.name
  }
}

/* output "argocd_admin_password" {
  description = "Contraseña inicial de admin de ArgoCD"
  value       = data.kubernetes_secret.argocd_initial_password.data.password
  sensitive   = true
} */

/* output "argocd_applications" {
  description = "Aplicaciones desplegadas en ArgoCD"
  value = {
    erpnext = {
      name      = argocd_application.erpnext.metadata[0].name
      namespace = argocd_application.erpnext.spec[0].destination[0].namespace
      status    = argocd_application.erpnext.status[0].sync_status
    }
  }
} */