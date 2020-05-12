# Contents

### Frappe/ERPNext Helm Chart

Helm Chart to deploy a *frappe-bench*-like environment on Kubernetes. It adds following resources:

Deployments:

- erpnext : This deployment contains frappe/erpnext nginx reverse proxy and gunicorn containers.
- redis-cache : This is optional deployment created by default. Serves as cache.
- redis-queue : This is optional deployment created by default. Used by workers and scheduler containers.
- redis-socketio : This is optional deployment created by default. Used by frappe-socketio container.
- scheduler : This deployment contains frappe/erpnext scheduler.
- socketio : This deployment contains frappe-socketio container.
- worker-d : This deployment contains frappe/erpnext default worker.
- worker-l : This deployment contains frappe/erpnext long worker.
- worker-s : This deployment contains frappe/erpnext short worker.

Services:

- redis-cache : This service exposes pod from redis-cache deployment.
- redis-queue : This service exposes pod from redis-queue deployment.
- redis-socketio : This service exposes pod from redis-socketio deployment.
- erpnext : This service exposes pods from erpnext deployment.
- socketio : This service exposes pods from socketio deployment.

PVC:

- erpnext : This persistent volume claim is used to allocate volume for sites and config deployed with this release

Jobs:

- migrate-sites : This is optional job that can be triggered on update

ServiceAccounts:

- erpnext : This service account is used by all deployments.

### Release Wizard

This is a release script for maintainers. It does the following:

- Clones frappe and erpnext locally,
- Checks latest tag for given major release.
- Validates that release always bumps up.
- Bumps values.yaml and Chart.yaml for release changes
- Adds git tag for chart version
- Push to selected remote

This will trigger travis to publish new version of helm chart.
