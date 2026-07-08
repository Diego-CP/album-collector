variable "project" {
  type        = string
  default     = "album-collector"
  description = "Project name prefix used in resource names/tags."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev/staging/prod)."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for the VPC."
}

variable "az_count" {
  type        = number
  default     = 2
  description = "Number of AZs to spread across."

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4 (region AZ availability permitting)."
  }
}
