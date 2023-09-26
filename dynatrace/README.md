# Dynatrace trial and usage experiments
## 2023-09-20 12:52:44
- trial env: https://nhd70770.live.dynatrace.com
- https://www.dynatrace.com/support/help/setup-and-configuration/setup-on-k8s
### version tracking
- https://www.dynatrace.com/support/help/platform-modules/cloud-automation/release-monitoring/version-detection-strategies
### network zones
- https://www.dynatrace.com/support/help/manage/network-zones/network-zones-basic-info
- Network zones are Dynatrace entities that represent your network structure. 
- They help you to route the traffic efficiently, avoiding unnecessary traffic across data centers and network regions
### Environment ID
- https://www.dynatrace.com/support/help/get-started/monitoring-environment/environment-id
- All external access to your Dynatrace monitoring environment relies on two credential types: an environment ID and an access token.

- Each environment that you monitor with Dynatrace is identified with a unique character string—the **environment ID**. 
- The Dynatrace API relies heavily on environment IDs to ensure that it pulls monitoring data from and pushes relevant external events to the correct Dynatrace environments.
- https://{your-environment-id}.live.dynatrace.com/
### access tokens and permissions
- https://www.dynatrace.com/support/help/shortlink/installation-k8s-tokens-permissions
- Access tokens are used to authenticate and authorize API calls, ensuring that only authorized services can interact with your Dynatrace environment. 
- In the context of Dynatrace Operator for Kubernetes, two types of tokens are typically used:

- **Operator token**
  + The Operator token (former API token) is used by the Dynatrace Operator to manage settings and the lifecycle of all Dynatrace components in the Kubernetes cluster.

- **Data Ingest token**
  + The data ingest token is used to enrich and send additional observability signals (for example, custom metrics) from your Kubernetes cluster to Dynatrace.

My favorite search engine is [Duck Duck Go](https://duckduckgo.com).
### "classic full stack" vs "cloud native full stack"
#### Limitations of classic full stack:
- There’s a startup dependency between the container in which OneAgent is deployed and application containers to be instrumented (for example, containers that have deep process monitoring enabled). 
- The OneAgent container must be started and the oneagenthelper process must be running before the application container is launched so that the application can be properly instrumented.
#### cloud native
- https://www.dynatrace.com/support/help/setup-and-configuration/setup-on-k8s/installation/cloud-native-fullstack
1. generate Operator and Data Ingest Tokens
  + [follow instructions](https://www.dynatrace.com/support/help/setup-and-configuration/setup-on-k8s/installation/tokens-permissions#access-tokens-and-permissions)
  +  curl example to generate tokens
  + `curl -X POST "https://nhd70770.live.dynatrace.com/api/v2/apiTokens" -H "accept: application/json; charset=utf-8" -H "Content-Type: application/json; charset=utf-8" -d "{\"scopes\":[\"activeGateTokenManagement.create\",\"entities.read\",\"settings.read\",\"settings.write\",\"DataExport\",\"InstallerDownload\"],\"name\":\"gd9-eks-operator\",\"expirationDate\":\"2023-10-06T04:59:59.999Z\"}" -H "Authorization: Api-Token XXXXXXXX"`
  + `curl -X POST "https://nhd70770.live.dynatrace.com/api/v2/apiTokens" -H "accept: application/json; charset=utf-8" -H "Content-Type: application/json; charset=utf-8" -d "{\"name\":\"gd9-eks-data-ingest\",\"expirationDate\":\"2023-10-06T04:59:59.999Z\",\"scopes\":[\"events.ingest\",\"logs.ingest\",\"metrics.ingest\"]}" -H "Authorization: Api-Token XXXXXXXX"`
  gd9-eks-operator:  dt0c01.5WOXUZRRWO4HZJTKRKPT5MVU.EHJ5YQ22KBLFOUGCVT5GYPJKFNLHP3DXTXL3GSYNZGVTSTNH62KTZS4IVPPV5GHY
  gd9-eks-data-ingest: dt0c01.FS34BV7NJ3YRMS2JBXPACZRP.QKUCRZFOCQOVA7YXIRTS2LGCOCUFCFV3WSC2JNG5Q3JD6EWADTDQFBSM6ROPRNMC
2. create namespace:
 + `kubectl create namespace dynatrace`
3. install the operator:
  + `kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v0.13.0/kubernetes.yaml`
  + `kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v0.13.0/kubernetes-csi.yaml`
  + validation: `kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=300s`
4. Create secret for Access tokens: Operator and Data Ingest
  + `kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=<API_TOKEN>" --from-literal="dataIngestToken=<DATA_INGEST_TOKEN>"`
  + `kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=dt0c01.5WOXUZRRWO4HZJTKRKPT5MVU.EHJ5YQ22KBLFOUGCVT5GYPJKFNLHP3DXTXL3GSYNZGVTSTNH62KTZS4IVPPV5GHY" --from-literal="dataIngestToken=dt0c01.FS34BV7NJ3YRMS2JBXPACZRP.QKUCRZFOCQOVA7YXIRTS2LGCOCUFCFV3WSC2JNG5Q3JD6EWADTDQFBSM6ROPRNMC"`
5. `kubectl apply -f cloudNativeFullStack.yml`

## Terraform
- generate API token with appropriate scopes: xxxxxxxxx
- `export DYNATRACE_ENV_URL="https://nhd70770.live.dynatrace.com"`
- `export DYNATRACE_API_TOKEN="xxxxxxx"`
- `cd src`
- `touch providers.tf`
- `terraform init`
## links
- dynatrace relase notes
- https://www.dynatrace.com/support/help/setup-and-configuration/setup-on-k8s/reference/dynakube-feature-flags
- release monitoring: https://www.dynatrace.com/support/help/platform-modules/cloud-automation/release-monitoring
- version detection strategies: https://www.dynatrace.com/support/help/platform-modules/cloud-automation/release-monitoring/version-detection-strategies