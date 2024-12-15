# variables.tf

variable "server_ip" {
  description = "Dirección IP del servidor on-premise donde está instalado MicroK8s"
  type        = string
}

variable "ssh_user" {
  description = "Usuario SSH para conectarse al servidor"
  type        = string
}

variable "ssh_private_key" {
  description = "Ruta al archivo de llave privada SSH"
  type        = string
}

variable "argocd_chart_version" {
  description = "Versión del chart de ArgoCD a instalar"
  type        = string
  default     = "7.7.10" # Ajusta según la última versión disponible
}

variable "argocd_namespace" {
  description = "Namespace donde se instalará ArgoCD"
  type        = string
  default     = "argocd"
}
