
## validate kubectl version
- `kubectl version --short`
- if you see this: `WARNING: version difference between client (1.22) and server (1.26) exceeds the supported minor version skew of +/-1`
  + update kubectl

## list cluster
- aws eks list-clusters

## install cert manager
- a popular tool in the Kubernetes ecosystem used for automating the management and issuance of TLS certificates
- cert-manager can issue certificates from various sources, such as Let's Encrypt, HashiCorp Vault, Venafi, as well as self-signed certificates, and can be used with various ingress solutions to secure your services.
- The ADOT Operator uses admission webhooks to mutate and validate the Collector Custom Resource (CR) requests
- In Kubernetes, the webhook requires a TLS certificate that the API server is configured to trust
- There are multiple ways for you to generate the required TLS certificate
- we will install the latest version of the cert-manager manually
- The cert-manager will generate a self-signed certificate
- `kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml`

```
namespace/cert-manager created
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io created
serviceaccount/cert-manager-cainjector created
serviceaccount/cert-manager created
serviceaccount/cert-manager-webhook created
configmap/cert-manager-webhook created
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrole.rbac.authorization.k8s.io/cert-manager-view created
clusterrole.rbac.authorization.k8s.io/cert-manager-edit created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
role.rbac.authorization.k8s.io/cert-manager:leaderelection created
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
service/cert-manager created
service/cert-manager-webhook created
deployment.apps/cert-manager-cainjector created
deployment.apps/cert-manager created
deployment.apps/cert-manager-webhook created
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
```
### cert-manager resource breakdown
- validate installation: `kubectl get pod -w -n cert-manager`

- **Namespace:** A dedicated space (cert-manager) for all cert-manager resources, ensuring isolation from other workloads.

- **CustomResourceDefinitions (CRDs):** These extend the Kubernetes API to support the custom resources needed by cert-manager, such as Certificate, ClusterIssuer, Issuer, and related resources. They represent different aspects of certificate management.

- **ServiceAccounts:** These are special accounts used by the cert-manager pods. Kubernetes uses service accounts to provide the identity for processes that run in a pod.

- **ConfigMaps:** Used to store configuration data as key-value pairs, and can be consumed by pods.

- **Roles and ClusterRoles:** These are sets of permissions that define what operations can be performed (like get, list, create, delete) on which resources. For instance, permissions to create events, read secrets, and update challenges.

- **RoleBindings and ClusterRoleBindings:** These bind roles to service accounts, granting the permissions defined in the role to the service accounts.

- **Services:** These expose the cert-manager and cert-manager-webhook pods as network services.

- **Deployments:** These ensure that the desired number of pod replicas are maintained. If a pod fails, the Deployment ensures that a new one replaces it.

- **Webhook configurations:** cert-manager uses a webhook for additional functionality. 
  + The MutatingWebhookConfiguration and ValidatingWebhookConfiguration are used to manage these webhooks. 
  + They watch for requests to certain resources and modify or validate the resources as needed.


## install namespace and permissions groundwork
- `kubectl apply -f https://amazon-eks.s3.amazonaws.com/docs/addons-otel-permissions.yaml`
  + namespace/opentelemetry-operator-system created
    - This creates an isolated environment within your Kubernetes cluster where OpenTelemetry components can operate
    - Namespaces allow for resource segmentation, limit resource usage, and provide a scope for resource naming
  + clusterrole.rbac.authorization.k8s.io/eks:addon-manager-otel created
    - ClusterRoles define a set of permissions that can be applied cluster-wide. 
    - This particular ClusterRole  provides the necessary permissions to manage OpenTelemetry resources throughout the EKS cluster
  + clusterrolebinding.rbac.authorization.k8s.io/eks:addon-manager-otel created
    - ClusterRoleBindings associate the permissions defined in a ClusterRole to a particular ServiceAccount or set of users
    - In this case, it's tying the permissions from the `eks:addon-manager-otel` ClusterRole to a specific service account
  + role.rbac.authorization.k8s.io/eks:addon-manager created
    - Unlike ClusterRoles, Roles are namespace-specific. 
    - This Role defines permissions necessary for managing resources specifically within the opentelemetry-operator-system namespace
  + rolebinding.rbac.authorization.k8s.io/eks:addon-manager created
    - RoleBindings tie the permissions defined in a Role to a specific ServiceAccount or set of users within a namespace. 
    - It connects the permissions from the `eks:addon-manager` Role to a service account in the opentelemetry-operator-system namespace.



## IRSA
```
eksctl create iamserviceaccount \
    --name adot-collector \
    --namespace opentelemetry-operator-system \
    --cluster dev-gd9 \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
    --approve \
    --override-existing-serviceaccounts
```

```
2023-08-12 05:40:33 [ℹ]  1 iamserviceaccount (opentelemetry-operator-system/adot-collector) was included (based on the include/exclude rules)
2023-08-12 05:40:33 [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
2023-08-12 05:40:33 [ℹ]  1 task: { 
    2 sequential sub-tasks: { 
        create IAM role for serviceaccount "opentelemetry-operator-system/adot-collector",
        create serviceaccount "opentelemetry-operator-system/adot-collector",
    } }2023-08-12 05:40:33 [ℹ]  building iamserviceaccount stack "eksctl-dev-gd9-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2023-08-12 05:40:33 [ℹ]  deploying stack "eksctl-dev-gd9-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2023-08-12 05:40:33 [ℹ]  waiting for CloudFormation stack "eksctl-dev-gd9-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2023-08-12 05:41:03 [ℹ]  waiting for CloudFormation stack "eksctl-dev-gd9-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2023-08-12 05:41:03 [ℹ]  created serviceaccount "opentelemetry-operator-system/adot-collector"
```

## install the ADOT operator
- `aws eks create-addon --addon-name adot --cluster-name dev-gd9`

```
{
    "addon": {
        "addonName": "adot",
        "clusterName": "dev-gd9",
        "status": "CREATING",
        "addonVersion": "v0.78.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-east-2:240195868935:addon/dev-gd9/adot/d4c4f49d-27db-a573-70b7-521d52885847",
        "createdAt": "2023-08-12T05:11:00.349000-05:00",
        "modifiedAt": "2023-08-12T05:11:00.368000-05:00",
        "tags": {}
    }
}
```
- **customizing the configuration:** https://aws-otel.github.io/docs/getting-started/adot-eks-add-on/add-on-configuration
- `aws eks describe-addon --addon-name adot --cluster-name dev-gd9`
- `k get pods -n opentelemetry-operator-system`
```
{
    "addon": {
        "addonName": "adot",
        "clusterName": "dev-gd9",
        "status": "ACTIVE",
        "addonVersion": "v0.78.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-east-2:240195868935:addon/dev-gd9/adot/d4c4f49d-27db-a573-70b7-521d52885847",
        "createdAt": "2023-08-12T05:11:00.349000-05:00",
        "modifiedAt": "2023-08-12T05:30:13.218000-05:00",
        "tags": {}
    }
}
```

## deploy the ADOT collector
- Once the ADOT EKS Add-On is running, you can deploy the ADOT Collector into your EKS cluster
- The ADOT Collector can be deployed in one of four modes: 
  + Deployment
  + Daemonset
  + StatefulSet
  + Sidecar

### customizing the configuration with a settings file
aws eks create-addon \
    --cluster-name "dev-gd9" \
    --addon-name adot \
    --configuration-values file://configuration.json \
    --resolve-conflicts=OVERWRITE
### validate
- `aws eks describe-addon --addon-name adot --cluster-name dev-gd9`
- kubectl get statefulset -n opentelemetry-operator-system




## consolidated steps
- `kubectl apply -f https://amazon-eks.s3.amazonaws.com/docs/addons-otel-permissions.yaml`
- secret: `k apply -f sa-secret.yml`
- irsa
```
eksctl create iamserviceaccount \
    --name adot-collector \
    --namespace opentelemetry-operator-system \
    --cluster dev-gd9 \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
    --approve \
    --override-existing-serviceaccounts
```
- patch service account: 
`kubectl patch serviceaccount adot-collector -n opentelemetry-operator-system --patch '{"secrets": [{"name": "adot-collector-token"}]}'`

- configuration from json file:
```
aws eks create-addon \
    --cluster-name dev-gd9 \
    --addon-name adot \
    --configuration-values file://configuration.json \
    --resolve-conflicts=OVERWRITE
```
- `aws eks describe-addon --addon-name adot --cluster-name dev-gd9`








- `aws eks create-addon --addon-name adot --cluster-name dev-gd9`
- `k get namespaces`
- `k get sa -n opentelemetry-operator-system`
  + `opentelemetry-operator` **note** this is not the "IRSA" serviceAccount

- `k get sa -n opentelemetry-operator-system`
  + `k get sa adot-collector -n opentelemetry-operator-system -o yaml`
- 

## links
- https://aws-otel.github.io/docs/getting-started/adot-eks-add-on/requirements
- sample apps: https://github.com/aws-observability/aws-otel-community/tree/master/sample-apps

aws eks update-addon \
--cluster-name dev-gd9 \
--addon-name adot \
--addon-version v0.78.0-eksbuild.1 \
--resolve-conflicts Overwrite \
--config file://configuration.json
