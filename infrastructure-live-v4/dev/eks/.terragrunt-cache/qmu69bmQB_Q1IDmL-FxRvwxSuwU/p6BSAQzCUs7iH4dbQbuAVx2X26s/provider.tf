# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
provider "aws" {
    region = "us-east-2"
}

provider "kubernetes" {
    # You can point to your kubeconfig or use other auth methods
    # The below assumes kubeconfig is in the default location and uses the current context
    config_path = "~/.kube/config"
}
