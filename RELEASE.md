# Releasing new helm charts

1. Make sure that all the relevant pull requests have been merged on the master branch

2. Setup release_wizard:
```shell
$ ./release_wizard/setup.sh
$ . ./venv/bin/activate
```

3. Run the release_wizard, which will fetch the latest version of Frappe/ERPNext, bump the chart version and the app version, and push to git and create a tag for the same.
```shell
$ ./release_wizard/wizard <number> major|minor|patch
```

4. The tag triggers travis, which will then build the chart and deploy it on helm.erpnext.com
