## configuration sections of source code values.yaml
- https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
- prometheus-operator: 1964
- prometheus: 2401
- alert-manager: 212
- nodeExporter: 1882
- kubeStateMetrics: 1808 

## helm templates
- `helm repo list`
- `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
- `helm template "47.1.0" prometheus-community/kube-prometheus-stack --values values.yml > rendered.yml`

## stack design
- https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.20.0/add-ons/kube-prometheus-stack/
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- *However, when using EKS, you also have the need to grant permissions to Kubernetes workloads running in the cluster*
- By utilizing IRSA, you can assign IAM roles directly to Kubernetes service accounts, allowing you to manage permissions and access control at a more granular level within your EKS cluster
- This feature enables you to leverage the existing IAM role-based access control model in AWS and extend it to the Kubernetes environment
- When you associate an IAM role with a service account, you can specify the permissions that the service account has within your cluster


## storage design
- Prometheus typically consumes local storage in the AWS EKS cluster to store its time-series data and other metrics
- By default, when you deploy the kube-prometheus-stack using Helm, it sets up Prometheus to use an emptyDir volume
- An emptyDir volume is a temporary storage within the pod's container, and it's created and deleted alongside the pod
- However, this means that if the Prometheus pod restarts or gets rescheduled, all the data stored in the emptyDir volume will be lost
- To ensure data persistence and avoid data loss in case of pod restarts or rescheduling, it's recommended to configure Prometheus to use Persistent Volume Claims (PVCs) to store its data on a more durable storage solution
- PVCs allow you to request and use storage volumes that exist beyond the lifecycle of the pod
- in order to construct the storage design we took some of Anton Putra's code (https://github.com/antonputra/tutorials/tree/main/lessons/154) and crafted the `2-csi-driver-addon.tf` file that handles both PVC creation and IAM for 


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
### integration
- In summary, the kube-prometheus-stack-operator service account is associated with the kube-prometheus-stack-operator cluster role through the kube-prometheus-stack-operator cluster role binding
- This setup allows the kube-prometheus-stack operator to act with the permissions defined in the cluster role (kube-prometheus-stack-operator) when managing and deploying resources within the cluster.
- The operator needs these permissions to create, update, and delete various resources like CustomResourceDefinitions (CRDs), Deployments, StatefulSets, etc., to set up and maintain the components of the kube-prometheus-stack (Prometheus, Grafana, Alertmanager, etc.) and ensure their proper functioning

### Prometheus Operator
- service account: kube-prometheus-stack-operator
- clusterRole: kube-prometheus-stack-operator
- clusterRoleBinding: kube-prometheus-stack-operator
### Prometheus
- service-account: kube-prometheus-stack-prometheus
- clusterRole: kube-prometheus-stack-prometheus
- clusterRoleBinding: kube-prometheus-stack-prometheus
- IRSA: 
## kube stack deployment
- add blueprints tf file: 2-kube-prom-stack.tf
- add `values.yml` to the same directory where the `2-kube-prom-stack.tf` is
- Helm template: 
  + `cd gd9-infrastructure/infrastructure-modules`
  + `helm template "47.1.0" prometheus-community/kube-prometheus-stack --values values.yml > rendered.yml`
- **deploy via Terragrunt**
  + `cd infrastructure-live-v4`
  + `terragrunt run-all apply`

## checkout
- `k get svc -n monitoring`
  + expected output: `prometheus-operated                ClusterIP   None             <none>        9090/TCP   64m`
- `k port-forward svc/prometheus-operated 9090 -n monitoring`
- check Status|Configuration
## links
- Anton Putra operator: https://github.com/antonputra/tutorials/tree/main/lessons/154
- https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.20.0/add-ons/kube-prometheus-stack/
- https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
- https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheusspec