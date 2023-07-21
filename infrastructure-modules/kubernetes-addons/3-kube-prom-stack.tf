data "aws_eks_cluster" "cluster" {
  name = "dev-gd9"
}




module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  cluster_name      = var.eks_name
  cluster_endpoint  = data.aws_eks_cluster.cluster.endpoint
  cluster_version   = data.aws_eks_cluster.cluster.version
  oidc_provider_arn = var.openid_provider_arn

  enable_kube_prometheus_stack = true

  kube_prometheus_stack = {
    name          = "kube-prometheus-stack"
    chart_version = "45.10.1"
    repository    = "https://prometheus-community.github.io/helm-charts"
    namespace     = "monitoring"
    values        = [templatefile("${path.module}/values.yml", {})]
  }
} 