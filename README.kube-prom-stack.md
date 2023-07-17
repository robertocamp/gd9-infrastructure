## configuration sections of source code values.yaml
- https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
- prometheus-operator: 1964
- prometheus: 2401
- alert-manager: 212
- nodeExporter: 1882
- kubeStateMetrics: 1808 

## helm templates
- `helm repo list`
- 'helm repo add prometheus-community https://prometheus-community.github.io/helm-charts '
## stack design

## kube stack deployment
- add blueprints tf file: 2-kube-prom-stack.tf
- add `values.yml` to the same directory where the `2-kube-prom-stack.tf` is

## links
- https://aws-ia.github.io/terraform-aws-eks-blueprints/v4.20.0/add-ons/kube-prometheus-stack/
- https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
- https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheusspec