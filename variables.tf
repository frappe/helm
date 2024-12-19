variable "kube_clusters" {
  description = "Map of Kubernetes clusters configurations"
  type        = map(any)
}

variable "kube_contexts" {
  description = "Map of Kubernetes contexts"
  type        = map(any)
}

variable "kube_users" {
  description = "Map of Kubernetes users"
  type        = map(any)
}

variable "selected_context" {
  description = "Selected Kubernetes context"
  type        = string
}

variable "branch_name" {
  description = "Branch name"
  type        = string
}