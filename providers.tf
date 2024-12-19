terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.2.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "kubernetes" {
  host                   = lookup(var.kube_clusters[lookup(var.kube_contexts, var.selected_context).cluster], "server", null)
  cluster_ca_certificate = base64decode(lookup(var.kube_clusters[lookup(var.kube_contexts, var.selected_context).cluster], "certificate_authority", ""))
  client_certificate     = base64decode(lookup(var.kube_users[lookup(var.kube_contexts, var.selected_context).user], "client_certificate", ""))
  client_key             = base64decode(lookup(var.kube_users[lookup(var.kube_contexts, var.selected_context).user], "client_key", ""))
}

provider "helm" {
  kubernetes {
    host                   = lookup(var.kube_clusters[lookup(var.kube_contexts, var.selected_context).cluster], "server", null)
    cluster_ca_certificate = base64decode(lookup(var.kube_clusters[lookup(var.kube_contexts, var.selected_context).cluster], "certificate_authority", ""))
    client_certificate     = base64decode(lookup(var.kube_users[lookup(var.kube_contexts, var.selected_context).user], "client_certificate", ""))
    client_key             = base64decode(lookup(var.kube_users[lookup(var.kube_contexts, var.selected_context).user], "client_key", ""))
  }
}

provider "argocd" {
  port_forward_with_namespace = "argocd"
  insecure    = true
  plain_text  = true
}