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

variable "kubernetes_version" {
  type        = string
  default     = "1.33"
  description = "EKS Kubernetes version."
}

variable "node_ami_type" {
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
  description = "AMI type. Graviton/arm64 EKS-optimized Amazon Linux 2023."
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t4g.medium", "t4g.large", "m6g.medium", "m7g.medium", "m6g.large"]
  description = "Graviton instance types for the node group. Variety to widen Spot instance pool."
}

variable "node_capacity_type" {
  type        = string
  default     = "SPOT"
  description = "Node capacity type."

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.node_capacity_type)
    error_message = "Must be SPOT or ON_DEMAND."
  }
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}
