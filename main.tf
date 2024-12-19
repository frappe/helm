module "argocd" {
  source = "git::https://github.com/mabecenter-it/argocd-app.git"

  branch_name = var.branch_name
}
