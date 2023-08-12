## configuration sections of source code values.yaml
- https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
- grafana: 856
- prometheus-operator: 1964
- prometheus: 2401
- alert-manager: 212
- nodeExporter: 1882
- kubeStateMetrics: 1808 

## prometheus operator
- the Prometheus Operator uses custom resources to simplify the deployment of and configuration of Prometheus, AlertManager and related monitoring components
- prometheus operator can help you create and discover targets in Kubernetes
- when you create a service monitor or pod monitor, Prometheus Operator will automatically convert it to Prometheus metrics

## helm templates
- `helm repo list`
- `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
- `cd infrastructure-modules/kubernetes-addons`
- `helm template "47.1.0" prometheus-community/kube-prometheus-stack --values values.yml > rendered.yml`

## stack design
- https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.20.0/add-ons/kube-prometheus-stack/
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- *However, when using EKS, you also have the need to grant permissions to Kubernetes workloads running in the cluster*
- By utilizing IRSA, you can assign IAM roles directly to Kubernetes service accounts, allowing you to manage permissions and access control at a more granular level within your EKS cluster
- This feature enables you to leverage the existing IAM role-based access control model in AWS and extend it to the Kubernetes environment
- When you associate an IAM role with a service account, you can specify the permissions that the service account has within your cluster
- the monitoring namespace:
```
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: "2023-07-17T00:52:01Z"
  labels:
    kubernetes.io/metadata.name: monitoring
    name: monitoring
  name: monitoring
```

### namespaces labels and serviceMonitors
- In this design, the label `monitoring: prometheus` on the namespace plays an important role in how the Prometheus Operator selects which namespaces to monitor
- In values.yml, we have defined *selectors* for both `serviceMonitorNamespaceSelector` and `podMonitorNamespaceSelector` that look for the `monitoring: prometheus` label on namespaces
- This means the Prometheus operator will only select `ServiceMonitors` and `PodMonitors` from namespaces that have the label monitoring:
- Services and Pods in namespaces which do not have the `monitoring: prometheus` label, won't be monitored.
- if namespaces were not deployed with this label, the label can be added:
  + `kubectl label namespace kube-system monitoring=prometheus`
  + **in future EKS deployments, add this label to the  namespace when the cluster is created**
- **once the namesapce is properly labeled, the individual serviceMonitors will also need labels**
  + in this design, the individual serviceMonitors must have the label `prometheus: main` in order to be picked up by Prometheus

#### serviceMonitors
- pods can be instrumented to expose prometheus metrics, for example a */metrics* endpoint, per pod
- a kubernetes service can then configured to expose traffic to our pods
- to get Prometheus to *scrape* the service, we deploy a serviceMonitor
- Prometheus uses a `selector` to discover the serviceMonitor
- the serviceMonitor, in turn, uses a `selector` to discover the application's Kubernetes service
- when these components are all properly wired together, the targets appear in the Prometheus dashboard
- if you are using `label selectors` , you need to be sure the labels exist on the serviceMonitors
- if you are telling Prometheus to select serviceMonitors with a specific label, and those serviceMonitors don't have the label, Prometheus will not select them
- a serviceMonitor needs to select a *Kubernetes service* to scrape
- the `selector` needs to have the right labels and look in the right namespace
- if your kubernetes service is missing the labels or is in the wrong namespace the serviceMonitor won't be able to select it

  
## storage design
- Prometheus typically consumes local storage in the AWS EKS cluster to store its time-series data and other metrics
- By default, when you deploy the kube-prometheus-stack using Helm, it sets up Prometheus to use an emptyDir volume
- An emptyDir volume is a temporary storage within the pod's container, and it's created and deleted alongside the pod
- However, this means that if the Prometheus pod restarts or gets rescheduled, all the data stored in the emptyDir volume will be lost
- To ensure data persistence and avoid data loss in case of pod restarts or rescheduling, it's recommended to configure Prometheus to use Persistent Volume Claims (PVCs) to store its data on a more durable storage solution
- PVCs allow you to request and use storage volumes that exist beyond the lifecycle of the pod
- in order to construct the storage design we took some of Anton Putra's code (https://github.com/antonputra/tutorials/tree/main/lessons/154) and crafted the `kubernetes-addons/2-csi-driver-addon.tf` file that handles  IAM for storage
- the PVC gets created in the Helm chart:

```
    storageSpec: 
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi
        selector: {}
```


## IAM, service accounts and IRSA
- IAM Roles for Service Accounts is a feature provided by AWS that allows you to associate IAM roles with Kubernetes service accounts running in an EKS cluster
- Traditionally, when working with AWS resources, you would use IAM roles to grant permissions to AWS services and resources
### service account
- The service account (kube-prometheus-stack-operator) is a Kubernetes resource used to provide an identity for the kube-prometheus-stack operator running in the EKS cluster
- It allows the operator to interact with the Kubernetes API and perform actions on behalf of the service account
- In this case, the kube-prometheus-stack-operator service account is used by the kube-prometheus-stack operator itself
### clusterRole
- The cluster role (kube-prometheus-stack-operator) is a Kubernetes resource that defines a set of permissions (i.e., rules) for certain API resources within the cluster
- A cluster role is a cluster-level resource and applies across all namespaces
- The kube-prometheus-stack-operator cluster role specifies what actions the service account (kube-prometheus-stack-operator) is allowed to perform on specific Kubernetes API resources, like Deployments, Pods, ConfigMaps, etc. It essentially defines the permissions needed by the operator to manage resources within the cluster
### clusterRoleBinding
- The cluster role binding (kube-prometheus-stack-operator) is a Kubernetes resource that binds the cluster role (kube-prometheus-stack-operator) to a specific subject, in this case, the service account (kube-prometheus-stack-operator)
- It grants the permissions defined in the cluster role to the service account, enabling the service account to perform the allowed actions on the specified resources within the cluster

### IRSA
#### what is "IRSA"
- IRSA (IAM roles for Service Accounts) is a mechanism for associating an IAM role with a specific Kubernetes Service Account, so that pods running under that service account can make AWS API calls with the permissions granted by the IAM role.
### integration
- In summary, the `kube-prometheus-stack-operator` service account is associated with the `kube-prometheus-stack-operator` cluster role through the `kube-prometheus-stack-operator` cluster role binding
- This setup allows the kube-prometheus-stack operator to act with the permissions defined in the cluster role (kube-prometheus-stack-operator) when managing and deploying resources within the cluster.
- The operator needs these permissions to create, update, and delete various resources like CustomResourceDefinitions (CRDs), Deployments, StatefulSets, etc., to set up and maintain the components of the kube-prometheus-stack (Prometheus, Grafana, Alertmanager, etc.) and ensure their proper functioning

### Prometheus Operator
- service account: `kube-prometheus-stack-operator`
- clusterRole: `kube-prometheus-stack-operator`
- clusterRoleBinding: `kube-prometheus-stack-operator`
### Prometheus
- service-account: `kube-prometheus-stack-prometheus`
- clusterRole: `kube-prometheus-stack-prometheus`
- clusterRoleBinding: `kube-prometheus-stack-prometheus`
#### IRSA
- an AWS IAM role named "prometheus" should be created
- add the TF code to create the prometheus role into the `3-kube-prom-stack.tf` file
- in values.yml, **add the IRSA annotation to the service account:**

```
  prometheus:
  enabled: true
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::240195868935:role/prometheus"
```

- trust relationship for prometheus role:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::240195868935:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/967879CF416BB62A1855CB7E6F4EA724"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-2.amazonaws.com/id/967879CF416BB62A1855CB7E6F4EA724:sub": "system:serviceaccount:monitoring:prometheus"
                }
            }
        }
    ]
}
```
- the prometheus IAM role is set up for use with IAM Roles for Service Accounts (IRSA). 
- This feature allows Kubernetes service accounts in your EKS cluster to assume AWS IAM roles. 
- This way, *you can granularly control AWS permissions for pods, independent of the node's IAM role*

#####  trust relationship breakdown
- **Principal** indicates which identities are trusted to assume this role. In this case, the identity is the OIDC provider associated with your EKS cluster.
- **Action**  is *sts:AssumeRoleWithWebIdentity*, which means the role trusts users authenticated through a web identity provider (in this case, OIDC for EKS).
- **Condition** specifies that only the prometheus service account within the monitoring namespace of your EKS cluster can assume this IAM role.
- `eks.amazonaws.com/role-arn: arn:aws:iam::240195868935:role/prometheus`
  + This annotation ties the service account to the IAM Role
  + When pods use this SA, they can assume this IAM Role to access AWS services.
##### EKS node IAM role vis-a-vis prometheus role
- The EKS nodes are all associated with the IAM instance profile `eks-e6c4b074-9f07-a7fc-a4b6-8b5afb7ecf9f`
-  This IAM instance profile is linked to an IAM role, which is what provides permissions. 
- The name of the Prometheus IAM role isn't evident in the IAM role associated with these EC2 instances. 
- Thus, it's safe to say that the prometheus role is not directly attached to the EKS nodes.



## namespace
- all stack components should be deployed into the `monitoring` namespace
### todo:  add creation of monitoring namespace to the EKS cluster creation
- `kubectl label namespace monitoring monitoring=prometheus`

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    monitoring: prometheus
```

## kube stack deployment
### current steps
- add blueprints tf file: 2-kube-prom-stack.tf
- add `values.yml` to the same directory where the `2-kube-prom-stack.tf` is
- Helm template: 
  + `cd infrastructure-modules/kubernetes-addons`
  + `helm template "47.1.0" prometheus-community/kube-prometheus-stack --values values.yml > rendered.yml`
- **deploy via Terragrunt**
  + `cd infrastructure-live-v4`
  + `terragrunt run-all apply`
  
## checkout
- `aws eks describe-cluster --name dev-gd9 --region us-east-2 --query 'cluster.createdAt'`
- `aws iam list-roles | jq -r '.Roles[] | select(.RoleName | test("prometheus"))'`
- `k get svc -n monitoring`
  + expected output: `prometheus-operated                ClusterIP   None             <none>        9090/TCP   64m`
- **activate prometheus UI:** `k port-forward svc/prometheus-operated 9090 -n monitoring`
  + connect to localhost:9090 in browser
  + you should get the app page
  + look for connection logs in the terminal
- check Status|Configuration

## application testing
1. `mkdir app` 
2. `cd app`
3. `go mod init github.com/robertocamp/gd9-infrastructure/app`
4. write app code
5. `go mod tidy`
6. local smoke test: `go run main.go`
7. ps aux | grep "main.go"
8. kill -9 {PID}
9. build docker image:
  + start Docker on mac
  + write Docker file
  + `docker build -t example-go-app .`
  + `docker image ls`
10. `run image locally: docker run --publish 8080:8080 myapp`
11. login to ECR: `aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 240195868935.dkr.ecr.us-east-2.amazonaws.com`
12. list your image repos: `aws ecr describe-repositories --region us-east-2`

12. create your image repo: `aws ecr create-repository --repository-name myapp --region us-east-2`
13. `docker push 240195868935.dkr.ecr.us-east-2.amazonaws.com/myapp:v0.1`
14. verify image in ECR: `aws ecr describe-repositories --region us-east-2`
14. create deployment files in `app/deploy`
  + namespace has a metadata label for `monitoring: prometheus`
  + image in deployment file should match ECR (**image and image tag**): `image: 240195868935.dkr.ecr.us-east-2.amazonaws.com/myapp:v0.1`
15. deployment:
```
❯ k apply -f deploy
namespace/staging created
deployment.apps/myapp created
service/myapp created
podmonitor.monitoring.coreos.com/myapp created
service/myapp-prom created
servicemonitor.monitoring.coreos.com/myapp created
```
16. checkouts:
  + check pod: `k get pods -n staging`
  + check svc: `k get svc -n staging`
  + check pod monitor: `k get PodMonitor -n staging`
  + check svc monitor: `k get ServiceMonitor -n staging`

17. open the Prometheus UI: `k port-forward svc/prometheus-operated 9090 -n monitoring`
18. you should see the podMonitor and serviceMonitor targets in the UI
19. check some metrics: put "tester" in the metrics search window --you should see the discovered metrics in the drop-down menu
  + choose "tester_duration_seconds" , `eg tester_duration_seconds{quantile="0.99"}`
  + then try `tester_duration_seconds_count` (a count metric only goes up --it's usually combined with a rate function)
20. endponts
```
❯ k describe endpoints myapp-prom  -n staging
Name:         myapp-prom
Namespace:    staging
Labels:       app=myapp-monitoring
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2023-08-03T07:21:45Z
Subsets:
  Addresses:          10.0.53.241
  NotReadyAddresses:  <none>
  Ports:
    Name          Port  Protocol
    ----          ----  --------
    http-metrics  8081  TCP

Events:  <none>
```
### node exporter
- The Node Exporter is a component of the Prometheus system that exposes hardware and OS metrics, such as disk I/O statistics, CPU load, memory, etc
- in order for Prometheus to work with node-exporter, we must integrate IRSA configuation so that the Prometheus service account can access AWS EC2 API
- The Prometheus Node Exporter is designed to run as a DaemonSet in Kubernetes, which means that it deploys a pod on every node in your cluster
- the Node Exporter component of the kube-prometheus-stack does not typically require an IAM Role for Service Account (IRSA).
- The Node Exporter works by exposing metrics from the underlying host, such as CPU usage, disk IO, network statistics, and so forth. 
- It obtains these metrics directly from the Linux kernel (from files in directories like /proc and /sys) rather than by making API calls to external services, so it does not need AWS IAM credentials
#### node exporter checkout
- *node exporter will not show up in `get pods`:*  `kubectl -n monitoring get ds`
  + The output will show you the number of desired pods (which should be equal to the number of nodes) and the current status of the pods.
- `kubectl -n monitoring get pods -l jobLabel=node-exporter`
- `kubectl -n monitoring logs -l jobLabel=node-exporter`
  + This command shows the logs of the pods, which can be helpful for troubleshooting if anything goes wrong.
- **check Prometheus targets** : 

### Grafana
- enable grafana defaults in values.yml
- run helm template command
- look at rendered.yml
- apply to cluster if satisfied with configuration
#### grafana checkout
- `k get pods -n monitoring`
- `k get svc -n monitoring`
- `k port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring`
-  default grafana login: admin
-  The password is auto-generated and stored in a Kubernetes secret:
-  `k get secrets -n monitoring`
  + `kubectl get secret --namespace monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

## kube-state-metrics
- simple service that listens to the Kubernetes API server and generates metrics about the state of various objects inside the cluster, such as deployments, nodes, pods, configmaps, services, and more
- It's different from other metrics because instead of measuring system metrics like CPU, memory, disk usage, I/O, etc., it focuses on cluster state and object statuses
- For instance, kube-state-metrics might expose metrics like:
  + Number of replicas vs. desired replicas for a deployment
  + The number of currently running pods vs. desired for a replicaset
  + The last time a node was ready
  + The number of endpoints attached to a service
  + The state of a persistent volume (bound, unbound, etc.)
- These metrics are usually prefixed with `kube_` when you view them in Prometheus


## coredns 
- AWS EKS comes with CoreDNS pods running by default to provide DNS services
- The kube-dns service in the kube-system namespace is the interface to these CoreDNS pods, facilitating DNS queries within the cluster
- The kube-prometheus-stack Helm chart by default provides monitoring resources for various Kubernetes components, including `coredns`
  + As part of this, the Helm chart creates the `kube-prometheus-stack-coredns` service in the `kube-system` namespace, which is set up to collect metrics from the `coredns` pods. These metrics are exposed by CoreDNS on **port 9153** by default.
- The ServiceMonitor for CoreDNS, which comes with the kube-prometheus-stack, is *designed to tell Prometheus where to scrape the metrics from*. 
  + By default, it targets the kube-prometheus-stack-coredns service:
```
  selector:
    matchLabels:
      app: kube-prometheus-stack-coredns
      release: "47.1.0"
  namespaceSelector:
    matchNames:
      - "kube-system"

```


- the kube stack will deploy a serviceMonitor for coredns:
```
# Source: kube-prometheus-stack/templates/exporters/core-dns/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: 47.1.0-kube-prometheus-sta-coredns
  namespace: monitoring
  labels:
    app: kube-prometheus-stack-coredns
    
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: 47.1.0
    app.kubernetes.io/version: "48.1.1"
    app.kubernetes.io/part-of: kube-prometheus-stack
    chart: kube-prometheus-stack-48.1.1
    release: "47.1.0"
    heritage: "Helm"
    project: gd9
spec:
  jobLabel: jobLabel
  
  selector:
    matchLabels:
      app: kube-prometheus-stack-coredns
      release: "47.1.0"
  namespaceSelector:
    matchNames:
      - "kube-system"
  endpoints:
  - port: http-metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
```
- When you create a Kubernetes cluster, either with EKS or most other Kubernetes distributions, it needs an internal DNS server to handle DNS resolution for service discovery within the cluster
- *CoreDNS is the default DNS server used by Kubernetes for this purpose*
- In the case of AWS EKS, when you create a new cluster, EKS sets up CoreDNS by default in the kube-system namespace to handle this internal DNS resolution. 
- This is a standard part of the EKS cluster setup, and the coredns pods are automatically deployed and managed by EKS to ensure your cluster has internal DNS capabilities from the get-go

- Based on this configuration, the `ServiceMonitor` resources are being selected if they are in namespaces labeled with `monitoring: prometheus` and if the ServiceMonitor itself has the label `prometheus: main`
- To add a label to the kube-system namespace, you can use the kubectl label command: `kubectl label namespace kube-system monitoring=prometheus`
- to add the `prometheus: main` label to the serviceMonitor, you must edit the values.yml and re-run Helm


### validation
- `kubectl get deployments -n monitoring | grep kube-state-metrics`
- `kubectl get servicemonitors.monitoring.coreos.com -n monitoring | grep kube-state-metrics`
- `kubectl port-forward -n monitoring svc/[kube-state-metrics-service-name] 8080:8080`
- `curl localhost:8080/metrics`
- validate serviceMonitor configuration: `kubectl get servicemonitors -n monitoring -o json | jq -r '.items[] | select(.metadata.labels.prometheus != "main") | .metadata.name'`


## port-forwarding
- `k port-forward svc/prometheus-operated 9090 -n monitoring`
- `k port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring`
- `ps -ef|grep port-forward`
- `kill -9 {PID}`


## links
- Anton Putra operator: https://github.com/antonputra/tutorials/tree/main/lessons/154
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.20.0/add-ons/kube-prometheus-stack/
- https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
- https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheusspec