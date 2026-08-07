variable "project" {
  type        = string
  default     = "album-collector"
  description = "Use as ECR repository name."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment name (dev/staging/prod)."
}

variable "image_tag_mutability" {
  type        = string
  default     = "IMMUTABLE"
  description = "Forbids overwriting an existing tag and forces unique tags."

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}
