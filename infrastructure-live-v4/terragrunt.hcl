remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region = "us-east-2"
}

provider "kubernetes" {
    # You can point to your kubeconfig or use other auth methods
    # The below assumes kubeconfig is in the default location and uses the current context
    config_path = "~/.kube/config
    "
}
EOF
}

