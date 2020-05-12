---
title: FAQ
layout: page
faq:
  - question: What can be scaled?
    answer: |
      Frappe SocketIO, Background Workers (default, short, long), and Gunicorn/Nginx Deployments can be scaled independently without any complexities involved.

      Use following command to scale deployments.

      ```console
      $ kubectl scale -n <namespace> deployment <deployment-name> --replicas <number>
      ```

      Redis Databases can be scaled independently by installing separate Redis cluster Helm Chart(s). Use the hostname(s) provided by these helm chart(s) as `redisCacheHost`, `redisQueueHost`, and `redisSocketIOHost`.

      It is unsure whether scheduler can be scaled out. It is set to `replica: 1` by default.
  - question: How do I edit files and directories on sites volume?
    answer: |
      Create file named `volume-editor.yaml`

      ```yaml
      kind: Pod
      apiVersion: v1
      metadata:
        name: volume-editor
      spec:
        volumes:
          - name: sites
            persistentVolumeClaim:
              claimName: <CLAIM NAME GOES HERE>
        containers:
          - name: debugger
            image: busybox
            # change ['sleep', 'infinity'] for pod to run infinitely
            command: ['sleep', '3600']
            volumeMounts:
              - mountPath: "/data"
                name: sites
      ```

      Change value for `spec.volumes[0].claimName` to `<helm-release-name>-erpnext` and create the resource in namespace where ERPNext is installed.

      Change the container image as per the need or editor of your choice.

      ```console
      $ kubectl -n <namespace> -f volume-editor.yaml
      ```

      Run an interactive shell inside the pod/container
      sites volume mounted at `/data`.

      ```console
      $ kubectl -n <namespace> exec -it volume-editor sh
      / #
      ```
      delete the pod after use
      ```console
      $ kubectl -n <namespace> delete -f volume-editor.yaml
      ```
  - question: How do I upgrade and migrate to the latest helm release?
    answer: |
      Execute following command:

      ```console
      $ helm repo update
      $ helm upgrade <release-name> -n <namespace> frappe/erpnext \
          --set mariadbHost=mariadb.mariadb.svc.cluster.local \
          --set persistence.storageClass=<storageClass> \
          --set migrateJob.enable=true
      ```

      Set `migrateJob.enable` to true if you know whether the image tag or the appVersion has changed. It will backup sites and migrate. Replace `<release-name>` with the installed helm release name, `<namespace>` with kubernetes namespace and `<storageClass>` with RWX storage class, e.g. `rook-cephfs`

  - question: How do I customize values for the ERPNext helm chart?
    answer: |
      Download the values.yaml file locally and modify the content as per need. e.g. change `socketIOImage.tag` to `edge` and use the file to set values during helm install.

      You may also use a custom image for your custom apps through the `-f values.yaml` or by using the `--set <key>=<value>` param.

      ```console
      $ wget -c https://raw.githubusercontent.com/frappe/helm/master/erpnext/values.yaml
      $ code values.yaml
      $ helm install <release-name> -n <namespace> frappe/erpnext -f values.yaml
      ```
---

<section class="faq">
	<ul>
		{% for item in page.faq %}
			<li><a href="#{{ item.question | slugify }}">{{ item.question }}</a></li>
		{% endfor %}
	</ul>

	{% for item in page.faq %}
		<h2 id="{{ item.question | slugify}}">{{ item.question }}<a class="header-link" href="#top">#</a></h2>
		{{ item.answer | markdownify }}
	{% endfor %}
</section>
