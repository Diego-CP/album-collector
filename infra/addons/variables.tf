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
  description = "Load Balancer Controller Helm chart version."
}

variable "external_dns_chart_version" {
  type        = string
  default     = "1.21.1"
  description = "ExternalDNS Helm chart version."
}
