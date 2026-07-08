terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in the bucket made in bootstrap
  # Bucket name needs to be added manually
  backend "s3" {
    bucket       = "album-collector-tfstate-822902368026"
    key          = "network/terraform.tfstate" # this stack's state path within the bucket
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3-native state locking (Terraform 1.10+)
  }
}
