# gd9-infrastructure


## Terraform: vpc infratstructure
- some 3rd party tooks require DNS support -enable this in the VPC
- Internet gateway provides Internet access for public subnets
- 2 private and 2 public subnets
  + public subnets use IG as default route 
  + private subnets use NATGW as default route
  + **subnet tags**
    - for EKS to function properly you need a  `kubernetes` tag with your clustername
    - `owned` or `shared`
    - Karpenter will use this tag to discover and auto-scale the cluster
    - if you want to expose your internal applications to the outside world, you would also need to assign `internal-elb` tag to private subnets
    - use `elb` tag in the public subnets
- nat gateway:  use manually assinged IP addr for NAT GW in case you need to whitelist the IP addr with clients in the future
- public and private routes get assigned to all subnets

### infrastructure-live-3
- VPC deployment to both `dev` and `staging` environments
- terragrunt design to deploy VPCs in multiple environments:
```
❯ tree .
.
├── dev
│   └── vpc
│       └── terragrunt.hcl
├── staging
│   └── vpc
│       └── terragrunt.hcl
└── terragrunt.hcl
```
- `cd infrastructure-live-v3/dev/vpc`
- `terragrunt init`
- `terragrunt apply`
```
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

private_subnet_ids = [
  "subnet-0d221615873a893cc",
  "subnet-084854168043d8333",
]
public_subnet_ids = [
  "subnet-0e75311415450c343",
  "subnet-097aaeefe47caa812",
]
vpc_id = "vpc-0710fdb48095c6dcd"
```

### infrastructure-live-4
#### design notes
- IAM role with `eks` principal: prerequisite to installing the EKS cluster
- attach a policy to this role which allows EKS to **create EC2 instances and load balancers**
- the IAM role gets attached to the cluster
- enable `endpoint_public_access` so that the cluster can be managed from a laptop connection
- a separate IAM role is created for the EKS nodes: `name = "${var.env}-${var.eks_name}-eks-nodes"`
- a list of policies is attached to the IAM role for nodes: `description = "List of IAM Policies to attach to EKS-managed nodes."`
- EKS-managed instances groups are created: `for_each = var.node_groups`
- all node groups must be connected to the cluster
- the initial setup contains instance type and capacity (we use "SPOT" in this code)
- the basic cluster scale is set with with the `scaling_config` map parameter (desired, max, min)
- to enable real autoscaling, you must deploy the **cluster autoscaler** or use **Karpenter**
- **OpenID connect** is typically used to grant access to the AWS API to applications in EKS
- we create the OIDC provider with the cluster and point it to the EKS control plane: 
  + `url = aws_eks_cluster.this.identity[0].oidc[0].issuer`


#### deployment
- **important**: as of this writing (July 2023) the **EKS cluster must be installed before addons** such as cluster-autoscaler because the addons require the OIDC ARN
- `cd infrastructure-live-v4/dev`
- `terragrunt run-all plan`
- `terragrunt run-all apply`
```
❯ tree .
.
├── dev
│   ├── eks
│   │   └── terragrunt.hcl
│   ├── env.hcl
│   └── vpc
│       └── terragrunt.hcl
└── terragrunt.hcl
```

```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

eks_name = "dev-gd8"
openid_provider_arn = "arn:aws:iam::240195868935:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/6DAA9A5AB5C3EFB24D8302C10AD84123"
```

#### checkout
- `aws eks list-clusters`
- `aws eks update-kubeconfig --name dev-gd9 --region us-east-2`
- `k get nodes`

#### addons
- typically you will add functionality to the cluster by installing addons such as
  + cluster autoscaling applications
  + CSI storage drivers
  + load balancer controllers
- we use a separate infrastructure module for addons:  `kubernetes-addons`
- addons are typically described as "managed" or "self-manged" and are often deployed as Helm charts
- Helm chart
  + create a `helm_release` with a Boolean flag that enables it
  + remote repository to use
  + chart name
  + namespace should match the namespace on the IAM role
  + service account name should match the IAM role: `name  = "rbac.serviceAccount.name"`
  + Helm provider authentication can be tricky: keep in mind you cannot pass variables from the EKS module here
  + this provider will be generated and can only use variables that are provided to the module itself
  + to initialize the Helm provider you need to get a temporary token
#### addons design
```
❯ pwd
/Users/robert/Documents/CODE/gd8-infrastructure/infrastructure-live-v4/dev
❯ tree .
.
├── eks
│   └── terragrunt.hcl
├── env.hcl
├── kubernetes-addons
│   └── terragrunt.hcl
└── vpc
    └── terragrunt.hcl
```

#### addons plan
```
Terraform will perform the following actions:

  # aws_iam_policy.cluster_autoscaler[0] will be created
  + resource "aws_iam_policy" "cluster_autoscaler" {
      + arn         = (known after apply)
      + id          = (known after apply)
      + name        = "dev-gd8-cluster-autoscaler"
      + name_prefix = (known after apply)
      + path        = "/"
      + policy      = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "autoscaling:DescribeAutoScalingGroups",
                          + "autoscaling:DescribeAutoScalingInstances",
                          + "autoscaling:DescribeLaunchConfigurations",
                          + "autoscaling:DescribeScalingActivities",
                          + "ec2:DescribeInstanceTypes",
                          + "ec2:DescribeLaunchTemplateVersions",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                  + {
                      + Action   = [
                          + "autoscaling:SetDesiredCapacity",
                          + "autoscaling:TerminateInstanceInAutoScalingGroup",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id   = (known after apply)
      + tags_all    = (known after apply)
    }

  # aws_iam_role.cluster_autoscaler[0] will be created
  + resource "aws_iam_role" "cluster_autoscaler" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRoleWithWebIdentity"
                      + Condition = {
                          + StringEquals = {
                              + "oidc.eks.us-east-2.amazonaws.com/id/6DAA9A5AB5C3EFB24D8302C10AD84123:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
                            }
                        }
                      + Effect    = "Allow"
                      + Principal = {
                          + Federated = "arn:aws:iam::240195868935:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/6DAA9A5AB5C3EFB24D8302C10AD84123"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "dev-gd8-cluster-autoscaler"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)
    }

  # aws_iam_role_policy_attachment.cluster_autoscaler[0] will be created
  + resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "dev-gd8-cluster-autoscaler"
    }

  # helm_release.cluster_autoscaler[0] will be created
  + resource "helm_release" "cluster_autoscaler" {
      + atomic                     = false
      + chart                      = "cluster-autoscaler"
      + cleanup_on_fail            = false
      + create_namespace           = false
      + dependency_update          = false
      + disable_crd_hooks          = false
      + disable_openapi_validation = false
      + disable_webhooks           = false
      + force_update               = false
      + id                         = (known after apply)
      + lint                       = false
      + manifest                   = (known after apply)
      + max_history                = 0
      + metadata                   = (known after apply)
      + name                       = "autoscaler"
      + namespace                  = "kube-system"
      + pass_credentials           = false
      + recreate_pods              = false
      + render_subchart_notes      = true
      + replace                    = false
      + repository                 = "https://kubernetes.github.io/autoscaler"
      + reset_values               = false
      + reuse_values               = false
      + skip_crds                  = false
      + status                     = "deployed"
      + timeout                    = 300
      + verify                     = false
      + version                    = "9.28.0"
      + wait                       = true
      + wait_for_jobs              = false

      + set {
          + name  = "autoDiscovery.clusterName"
          + value = "dev-gd8"
        }
      + set {
          + name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
          + value = (known after apply)
        }
      + set {
          + name  = "rbac.serviceAccount.name"
          + value = "cluster-autoscaler"
        }
    }

Plan: 4 to add, 0 to change, 0 to destroy.
```

#### addons checkout
- `helm list -A`
  + expected output: 
```
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
autoscaler      kube-system     1               2023-07-16 09:10:32.131851 -0500 CDT    deployed        cluster-autoscaler-9.28.0       1.26.2     
```
- `k get pods -n kube-system`
- `k logs autoscaler-aws-cluster-autoscaler-56c6c5f99b-5jscz -n kube-system`

## links
- anton putra eks: https://github.com/antonputra/tutorials/tree/main/lessons/160
- https://www.youtube.com/watch?v=yduHaOj3XMg&t=3026s
- https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/blob/main/docs/addons/kube-prometheus-stack.md
- markdown links: https://www.digitalocean.com/community/tutorials/markdown-markdown-images