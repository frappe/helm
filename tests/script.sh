#!/bin/bash

function waitForERPNextDeployment() {
  INCREMENT=0
  while [[ $(kubectl get -n erpnext deployment erpnext-${1}-erpnext -o 'jsonpath={..status.conditions[?(@.type=="Available")].status}') != "True" ]]; do
    echo "waiting for deployment erpnext-${1}-erpnext"
    sleep 3
    ((INCREMENT=INCREMENT+1))
    if [[ $INCREMENT -eq 600  ]]; then
      echo "timeout waiting for erpnext-${1}-erpnext"
      exit 1
    fi
  done
}

echo -e "\e[1m\e[4mCreate testcluster with k3d\e[0m"
k3d cluster create testcluster --api-port 127.0.0.1:6443 -p 80:80@loadbalancer -p 443:443@loadbalancer --k3s-server-arg "--no-deploy=traefik"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml
echo -e "\n"

echo -e "\e[1m\e[4mInstall bitnami/mariadb helm chart\e[0m"
kubectl create namespace mariadb
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install mariadb -n mariadb bitnami/mariadb -f tests/mariadb-local-values.yaml
echo -e "\n"

echo -e "\e[1m\e[4mInstall nfs-server-provisioner\e[0m"
kubectl create namespace nfs
kubectl create -f tests/nfs-server-provisioner/statefulset.yaml
kubectl create -f tests/nfs-server-provisioner/rbac.yaml
kubectl create -f tests/nfs-server-provisioner/class.yaml
echo -e "\n"

echo -e "\e[1m\e[4mWait for MariaDB and NFS to be ready\e[0m"
INCREMENT=0
while [[ $(kubectl get -n mariadb pods mariadb-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  echo "waiting for mariadb-0"
  sleep 3
  ((INCREMENT=INCREMENT+1))
  if [[ $INCREMENT -eq 600  ]]; then
    echo "timeout waiting for mariadb-0"
    exit 1
  fi
done

INCREMENT=0
while [[ $(kubectl get -n nfs pods nfs-provisioner-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  echo "waiting for nfs-provisioner-0"
  sleep 3
  ((INCREMENT=INCREMENT+1))
  if [[ $INCREMENT -eq 600  ]]; then
    echo "timeout waiting for nfs-provisioner-0"
    exit 1
  fi
done
echo -e "\n"

echo -e "\e[1m\e[4mInstall frappe/erpnext helm chart\e[0m"
kubectl create namespace erpnext
kubectl apply -f tests/mariadb-root-password.yaml
helm repo add frappe https://helm.erpnext.com
helm repo update
helm install erpnext-upstream --namespace erpnext frappe/erpnext --set mariadbHost=mariadb.mariadb.svc.cluster.local --set persistence.logs.storageClass=nfs --set persistence.worker.storageClass=nfs
echo -e "\n"

echo -e "\e[1m\e[4mWait for ERPNext deployment to start\e[0m"
waitForERPNextDeployment upstream
echo -e "\n"

echo -e "\e[1m\e[4mCreate new site job (mysite.localhost)\e[0m"
kubectl apply -f tests/create-mysite-localhost.yaml
kubectl apply -f tests/mysite-localhost-ingress.yaml
echo -e "\n"

echo -e "\e[1m\e[4mWait for site creation job to complete\e[0m"
kubectl -n erpnext wait --timeout=1800s --for=condition=complete job/create-new-site-mysite.localhost
echo -e "\n"

echo -e "\e[1m\e[4mPing mysite.localhost\e[0m"
curl -s http://mysite.localhost/api/method/ping
echo -e "\n"

echo -e "\e[1m\e[4mUpgrade to chart from PR\e[0m"
helm upgrade erpnext-upstream --namespace erpnext erpnext --set mariadbHost=mariadb.mariadb.svc.cluster.local --set persistence.logs.storageClass=nfs --set persistence.worker.storageClass=nfs --set migrateJob.enable=true
echo -e "\n"

echo -e "\e[1m\e[4mWait for site migration job to complete\e[0m"
kubectl -n erpnext wait --timeout=1800s --for=condition=complete jobs --all
echo -e "\n"

echo -e "\e[1m\e[4mPing mysite.localhost\e[0m"
curl -s http://mysite.localhost/api/method/ping
echo -e "\n"

echo -e "\e[1m\e[4mDelete erpnext-upstream\e[0m"
helm delete -n erpnext erpnext-upstream
echo -e "\n"

echo -e "\e[1m\e[4mInstall frappe/erpnext helm chart\e[0m"
helm install erpnext-pr --namespace erpnext erpnext --set mariadbHost=mariadb.mariadb.svc.cluster.local --set persistence.logs.storageClass=nfs --set persistence.worker.storageClass=nfs
echo -e "\n"

echo -e "\e[1m\e[4mCreate new site job (mysite.localhost)\e[0m"
kubectl apply -f tests/create-prsite-localhost.yaml
kubectl apply -f tests/prsite-localhost-ingress.yaml
echo -e "\n"

echo -e "\e[1m\e[4mWait for site creation job to complete\e[0m"
kubectl -n erpnext wait --timeout=1800s --for=condition=complete job/create-new-site-prsite.localhost
echo -e "\n"

echo -e "\e[1m\e[4mWait for ERPNext deployment to start\e[0m"
waitForERPNextDeployment pr
sleep 3
# Confirm deployment is available
waitForERPNextDeployment pr
sleep 3
echo -e "\n"

echo -e "\e[1m\e[4mPing prsite.localhost\e[0m"
curl -s http://prsite.localhost/api/method/ping
echo -e "\n"
