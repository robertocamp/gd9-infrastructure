data "aws_eks_cluster" "cluster" {
  name = "dev-gd9"
}


data "aws_iam_policy_document" "prometheus" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:monitoring:prometheus"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "prometheus" {
  assume_role_policy = data.aws_iam_policy_document.prometheus.json
  name               = "prometheus"
}

resource "aws_iam_role_policy_attachment" "prometheus" {
  role       = aws_iam_role.prometheus.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
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
    values        = [templatefile("${path.module}/values.yml", { role_arn = aws_iam_role.prometheus.arn })]
  }

  depends_on = [aws_iam_role.prometheus]
} 
