# terraform.tfvars

server_ip        = "192.168.99.115"            # Cambia por la IP de tu servidor
ssh_user         = "kube"                  # Cambia por el usuario SSH adecuado
ssh_private_key  = "/home/jorge/.ssh/id_rsa" # Cambia por la ruta a tu llave privada
# argocd_chart_version y argocd_namespace ya tienen valores por defecto, pero puedes sobrescribirlos si lo deseas
alb_name = "your-alb-name"
