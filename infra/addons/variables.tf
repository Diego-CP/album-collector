variable "project" {
  type    = string
  default = "album-collector"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "lbc_chart_version" {
  type        = string
  default     = "1.14.0"
  description = <<-EOT
    AWS Load Balancer Controller Helm chart version. Check the latest compatible
    version with:
      helm repo add eks https://aws.github.io/eks-charts && helm repo update
      helm search repo eks/aws-load-balancer-controller --versions
  EOT
}
