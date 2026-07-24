terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # EKS module v21 requires provider v6+
    }
  }

  backend "s3" {
    bucket       = "album-collector-tfstate-822902368026"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
