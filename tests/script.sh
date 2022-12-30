#!/bin/bash

echo -e "\e[1m\e[4mCreate testcluster with k3d and kubernetes/ingress-nginx\e[0m"
k3d cluster create testcluster --api-port 127.0.0.1:6443 -p 80:80@loadbalancer -p 443:443@loadbalancer --k3s-arg "--disable=traefik@server:0"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
echo -e "\n"

echo -e "\e[1m\e[4mAdd Helm Repositories\e[0m"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner
helm repo add frappe https://helm.erpnext.com
helm repo update
echo -e "\n"

echo -e "\e[1m\e[4mCreate mariadb release from bitnami/mariadb helm chart\e[0m"
kubectl create namespace mariadb
helm install mariadb -n mariadb bitnami/mariadb -f tests/mariadb/values.yaml --version 11.4.2 --wait
echo -e "\n"

echo -e "\e[1m\e[4mCreate in-cluster release from nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner helm chart\e[0m"
kubectl create namespace nfs
helm install in-cluster -n nfs nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner -f tests/nfs/values.yaml --version 1.4.0 --wait
echo -e "\n"

echo -e "\e[1m\e[4mCreate frappe-bench release from frappe/erpnext helm chart\e[0m"
kubectl create namespace erpnext
helm install frappe-bench --namespace erpnext frappe/erpnext -f tests/erpnext/values.yaml --wait
echo -e "\n"

echo -e "\e[1m\e[4mCreate mysite.localhost\e[0m"
helm template frappe-bench \
  -n erpnext erpnext \
  -f tests/erpnext/values.yaml \
  -f tests/erpnext/values-job-create-mysite.yaml \
  -s templates/job-create-site.yaml \
  | kubectl -n erpnext apply -f -
helm template frappe-bench -n erpnext erpnext -f tests/erpnext/values.yaml -f tests/erpnext/values-ingress-mysite.yaml -s templates/ingress.yaml | kubectl -n erpnext apply -f -
echo -e "\n"

echo -e "\e[1m\e[4mWait for site creation job to complete\e[0m"
kubectl -n erpnext wait --timeout=1800s --for=condition=complete jobs --all
echo -e "\n"

echo -e "\e[1m\e[4mPing mysite.localhost (upstream chart)\e[0m"
curl -sS http://mysite.localhost/api/method/ping
echo -e "\n"

echo -e "\e[1m\e[4mUpgrade frappe-bench release with chart from PR\e[0m"
helm upgrade frappe-bench -n erpnext erpnext -f tests/erpnext/values.yaml --wait
echo -e "\n"

echo -e "\e[1m\e[4mPing mysite.localhost (pr chart)\e[0m"
curl -sS http://mysite.localhost/api/method/ping
echo -e "\n"
