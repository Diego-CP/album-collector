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

variable "database_name" {
  type        = string
  default     = "albumcollector"
  description = "Initial database name."
}

variable "master_username" {
  type        = string
  default     = "dbadmin"
  description = "Master username. Password is RDS-managed."
}

variable "engine_version" {
  type        = string
  default     = "8.0.mysql_aurora.3.08.0"
  description = "Aurora MySQL version. 3.08+ for min_capacity=0."
}

variable "min_capacity" {
  type        = number
  default     = 0
  description = "Minimum ACUs."
}

variable "max_capacity" {
  type        = number
  default     = 2
  description = "Maximum ACUs."
}

variable "seconds_until_auto_pause" {
  type        = number
  default     = 300
  description = "Idle seconds before auto-pause."
}

variable "instance_count" {
  type        = number
  default     = 1
  description = "Single writer volume. TODO: Set to 2 in prod."
}
