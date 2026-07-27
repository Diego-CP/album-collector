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

variable "eso_chart_version" {
  type        = string
  default     = "2.8.0"
  description = "External Secrets Operator Helm chart version."
}

variable "metrics_server_chart_version" {
  type        = string
  default     = "3.13.1"
  description = "metrics-server Helm chart version."
}

variable "cluster_autoscaler_chart_version" {
  type        = string
  default     = "9.59.0"
  description = "Cluster Autoscaler Helm chart version."
}
