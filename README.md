# Contents

### Frappe/ERPNext Helm Chart

Helm Chart to deploy a *frappe-bench*-like environment on Kubernetes. It adds following resources:

ConfigMaps:

- `nginx-config` is used to override template to render default.conf for nginx reverse proxy and static assets container.

Deployments:

- `gunicorn` deployment contains frappe/erpnext nginx reverse proxy and gunicorn containers.
- `nginx` deployment contains frappe/erpnext nginx reverse proxy and gunicorn containers.
- `scheduler` deployment contains frappe/erpnext scheduler.
- `socketio` deployment contains frappe-socketio container.
- `worker-d` deployment contains frappe/erpnext default worker.
- `worker-l` deployment contains frappe/erpnext long worker.
- `worker-s` deployment contains frappe/erpnext short worker.

Ingresses:

- `ingress` with custom name can be dynamically generated using `helm template` and configured values.

Jobs:

- `vol-fix`
- `bench-conf`
- `create-site`
- `drop-site`
- `backup-push`
- `migrate`

PVC:

- `erpnext` persistent volume claim is used to allocate volume for sites and config deployed with this release
- `erpnext-logs` persistent volume claim is used to allocate volume for logs

Secrets:

- `secret` is used to store `db-root-password` for external db host

Services:

- `gunicorn` service exposes pods from gunicorn deployment.
- `nginx` service exposes pods from nginx deployment.
- `socketio` service exposes pods from socketio deployment.

ServiceAccounts:

- `erpnext` service account is used by all deployments.

### Release Wizard

This is a release script for maintainers. It does the following:

- Checks latest tag for given major release for frappe and erpnext using git.
- Validates that release always bumps up.
- Bumps values.yaml and Chart.yaml for release changes
- Adds git tag for chart version
- Push to selected remote

This will trigger workflow to publish new version of helm chart.
