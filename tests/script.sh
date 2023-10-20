#!/bin/bash

echo -e "\e[1m\e[4mInstall kubectl\e[0m"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

echo -e "\e[1m\e[4mInstall Helm\e[0m"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo -e "\e[1m\e[4mConfigure K3s\e[0m"
mkdir -p /root/.kube
curl k3s:8081 -o /root/.kube/config
chmod go-r /root/.kube/config
export KUBECONFIG=/root/.kube/config
kubectl cluster-info

echo -e "\e[1m\e[4mInstall kubernetes/ingress-nginx\e[0m"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
echo -e "\n"

echo -e "\e[1m\e[4mAdd Helm Repositories\e[0m"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner
helm repo add frappe https://helm.erpnext.com
helm repo update
echo -e "\n"

echo -e "\e[1m\e[4mCreate mariadb release from bitnami/mariadb helm chart\e[0m"
kubectl create namespace mariadb
helm install mariadb -n mariadb bitnami/mariadb -f tests/mariadb/values.yaml --version 11.5.7 --wait
echo -e "\n"

echo -e "\e[1m\e[4mCreate in-cluster release from nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner helm chart\e[0m"
kubectl create namespace nfs
helm install in-cluster -n nfs nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner -f tests/nfs/values.yaml --wait
echo -e "\n"

echo -e "\e[1m\e[4mCreate frappe-bench release from frappe/erpnext helm chart\e[0m"
kubectl create namespace erpnext
helm install frappe-bench --namespace erpnext frappe/erpnext -f tests/erpnext/values.yaml --wait --timeout=15m0s
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
curl -sS -H "Host: mysite.localhost" http://k3s/api/method/ping
echo -e "\n"

echo -e "\e[1m\e[4mUpgrade frappe-bench release with chart from PR\e[0m"
helm upgrade frappe-bench -n erpnext erpnext -f tests/erpnext/values.yaml --wait --timeout=15m0s
echo -e "\n"

echo -e "\e[1m\e[4mMigrate mysite.localhost\e[0m"
helm template frappe-bench \
  -n erpnext erpnext \
  -f tests/erpnext/values.yaml \
  -f tests/erpnext/values-job-migrate-mysite.yaml \
  -s templates/job-migrate-site.yaml > /tmp/migrate-job.yaml
kubectl -n erpnext apply -f /tmp/migrate-job.yaml
JOBNAME=$(yq '.metadata.name' /tmp/migrate-job.yaml)
export JOBNAME
echo -e "\n"

echo -e "\033[1mWaiting for "${JOBNAME}" to complete\033[0m"
JOBUUID=$(kubectl -n erpnext get job "${JOBNAME}" -o jsonpath="{.metadata.uid}")
export JOBUUID
PODNAME=$(kubectl -n erpnext get pod -l controller-uid="${JOBUUID}" -o name)
export PODNAME
echo "Job name ${JOBNAME} / Job uuid ${JOBUUID}"
echo "Pod name ${PODNAME}"
kubectl -n erpnext wait --timeout=900s --for=condition=ready "${PODNAME}"
echo "Migration Logs..."
kubectl -n erpnext logs job/${JOBNAME} -f

echo -e "\e[1m\e[4mPing mysite.localhost (pr chart)\e[0m"
curl -sS -H "Host: mysite.localhost" http://k3s/api/method/ping
echo -e "\n"

echo -e "\e[1m\e[4mCleanup\e[0m"
kubectl delete ingress -n erpnext --all
kubectl delete jobs -n erpnext --all
helm delete --wait -n erpnext frappe-bench
helm delete --wait -n mariadb mariadb
helm delete --wait -n nfs in-cluster
kubectl delete pvc -n erpnext --all
kubectl delete pvc -n mariadb --all
kubectl delete pvc -n nfs --all
