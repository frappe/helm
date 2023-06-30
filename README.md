# Contents

### Frappe/ERPNext Helm Chart

Helm Chart to deploy a *frappe-bench*-like environment on Kubernetes. It adds following resources:

ConfigMaps:

- `nginx-config` is used to override default.conf for nginx reverse proxy and static assets container.

Deployments:

- `gunicorn` deployment contains frappe/erpnext gunicorn.
- `nginx` deployment contains frappe/erpnext static assets and nginx reverse proxy.
- `scheduler` deployment contains frappe/erpnext scheduler.
- `socketio` deployment contains frappe/erpnext socketio.
- `worker-d` deployment contains frappe/erpnext default worker.
- `worker-l` deployment contains frappe/erpnext long worker.
- `worker-s` deployment contains frappe/erpnext short worker.

HorizontalPodAutoscalers:

- `gunicorn` hpa scales frappe/erpnext gunicorn deployment.
- `nginx` hpa scales frappe/erpnext nginx deployment.
- `socketio` hpa scales frappe/erpnext socketio deployment.
- `worker-d` hpa scales frappe/erpnext default worker deployment.
- `worker-l` hpa scales frappe/erpnext long worker deployment.
- `worker-s` hpa scales frappe/erpnext short worker deployment.

Ingresses:

- `ingress` with custom name can be dynamically generated using `helm template` and configured values.

Jobs:

- `vol-fix` job to fix volume permissions, changes the `uid` and `gid` to `1000:1000`.
- `bench-conf` job to configure db host, redis hosts and socketio port.
- `create-site` job to create new site.
- `drop-site` job to drop existing site.
- `backup-push` job to backup and optionally push backup to S3 for existing site.
- `migrate` job to migrate existing site.
- `custom` job to run custom additional commands and configuration.

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
