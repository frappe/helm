---
title: FAQ
layout: page
faq:
  - question: What are steps for beginners to install ERPNext on Kubernetes?
    answer: |
      Install ingress controller. Cloud provider specific commands differ. Read more about [kubernetes/ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy) before installing.

      ```console
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml
      ```

      Install [Cert Manager](https://cert-manager.io/docs/installation) and create [Issuer or ClusterIssuer](https://cert-manager.io/docs/tutorials/acme/http-validation).


      [Install ERPNext](/)

      [Generate Additional Resources](https://github.com/frappe/helm/blob/main/erpnext/README.md#generate-additional-resources) to create site, ingress, backup jobs, etc.

  - question: What can be scaled?
    answer: |
      Frappe SocketIO, Background Workers (default, short, long), Gunicorn and Nginx Deployments can be scaled independently without any complexities involved.

      Use following command to scale deployments.

      ```console
      $ kubectl scale -n <namespace> deployment <deployment-name> --replicas <number>
      ```

      It is unsure whether scheduler can be scaled out. It is set to `replica: 1` by default.
  - question: How to auto scale deployments?
    answer: |
      Use [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale) to auto scale required deployments.

      Example to auto scale `Deployment/frappe-bench-worker-d`, apply following `hpa.yaml`.

      ```yaml
      # hpa.yaml
      apiVersion: autoscaling/v1
      kind: HorizontalPodAutoscaler
      metadata:
        name: frappe-bench-worker-d
      spec:
        maxReplicas: 5
        minReplicas: 1
        scaleTargetRef:
          apiVersion: apps/v1
          kind: Deployment
          name: frappe-bench-worker-d
        targetCPUUtilizationPercentage: 60
      ```

      Create the resource.

      ```console
      $ kubectl apply -n <namespace> -f hpa.yml
      ```
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
      $ helm upgrade frappe-bench --namespace erpnext frappe/erpnext --set persistence.worker.storageClass=nfs
      ```

      Generate resource to [create site migration job](https://github.com/frappe/helm/blob/main/erpnext/README.md#migrate-site)

  - question: How do I customize values for the ERPNext helm chart?
    answer: |
      Download the values.yaml file locally and modify the content as per need. e.g. change `socketIOImage.tag` to `edge` and use the file to set values during helm install.

      You may also use a custom image for your custom apps through the `-f values.yaml` or by using the `--set <key>=<value>` param.

      ```console
      $ wget -c https://raw.githubusercontent.com/frappe/helm/master/erpnext/values.yaml
      $ code values.yaml
      $ helm install <release-name> -n <namespace> frappe/erpnext -f values.yaml
      ```
  - question: How do I add custom domain to existing site?
    answer: |
      Example is using Kubernetes Nginx ingress [annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/).

      Create ingress resource with desired domain name with following annotation:

      ```yaml
      ...
      annotations:
        nginx.ingress.kubernetes.io/upstream-vhost: main-site.example.com
      ...
      spec:
        rules:
        - host: custom-site.example.com
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
