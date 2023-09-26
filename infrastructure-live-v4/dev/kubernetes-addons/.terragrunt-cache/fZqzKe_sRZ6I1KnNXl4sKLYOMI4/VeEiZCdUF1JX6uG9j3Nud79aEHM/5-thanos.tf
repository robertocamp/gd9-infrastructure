

// IAM Policy for Thanos
resource "aws_iam_policy" "thanos_s3_access" {
  name        = "ThanosS3Access"
  description = "Permissions for Thanos to access S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload"
        ],
        Effect = "Allow",
        Resource = [
          var.thanos_bucket_arn,
          "${var.thanos_bucket_arn}/*"
          // "arn:aws:s3:::gd9-thanos",
          // "arn:aws:s3:::gd9-thanos/*"
        ]
      }
    ]
  })
}

// IAM Role for Thanos with OIDC Trust Relationship

data "aws_iam_policy_document" "thanos_assume_web_identity" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:monitoring:thanos"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "thanos" {
  assume_role_policy = data.aws_iam_policy_document.thanos_assume_web_identity.json
  name               = "thanos"
}

resource "aws_iam_role_policy_attachment" "thanos" {
  role       = aws_iam_role.thanos.name
  policy_arn = aws_iam_policy.thanos_s3_access.arn
}


// Kubernetes Service Account with Annotation
resource "kubernetes_service_account" "thanos" {
  metadata {
    name      = "thanos"
    namespace = "monitoring"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.thanos.arn
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_secret" "thanos_object_storage" {
  metadata {
    name      = "thanos-objectstorage"
    namespace = "monitoring"
  }

  data = {
    "thanos.yaml" = filebase64("${path.module}/thanos.yaml")
  }

  type = "Opaque"
}


