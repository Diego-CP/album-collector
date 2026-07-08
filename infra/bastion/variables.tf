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

variable "instance_type" {
  type        = string
  default     = "t4g.nano"
  description = "Burstable Graviton (arm64) nano."
}
