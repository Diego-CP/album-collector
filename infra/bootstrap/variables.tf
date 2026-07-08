variable "project" {
  type        = string
  default     = "album-collector"
  description = "Project name prefix used in resource names."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for the state bucket."
}
