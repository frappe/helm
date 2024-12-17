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
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.4"
    }
    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.2.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Ruta por defecto de kubeconfig para MicroK8s
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

provider "argocd" {
  port_forward_with_namespace = var.argocd_namespace
  insecure    = true
  plain_text  = true
}
