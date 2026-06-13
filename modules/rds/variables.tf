variable "project_name" { type = string }
variable "environment" { type = string }

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the RDS instance"
  type        = list(string)
}

variable "engine" {
  description = "mysql or postgres"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling in GiB"
  type        = number
  default     = 100
}

variable "db_name" {
  type = string
}

variable "username" {
  type      = string
  sensitive = true
}

variable "password" {
  type      = string
  sensitive = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = true
}
