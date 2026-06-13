# ─────────────────────────────────────────────
# Global
# ─────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name — used as a prefix on every resource name"
  type        = string
  default     = "3tier-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development."
  }
}

# ─────────────────────────────────────────────
# Networking
# ─────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones — minimum 2 required for high availability"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public (web-tier) subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private (app-tier) subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for database subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

# ─────────────────────────────────────────────
# Web Tier
# ─────────────────────────────────────────────
variable "web_ami_id" {
  description = "AMI ID for web-tier EC2 instances. Leave empty to auto-resolve the latest Amazon Linux 2023 AMI for the configured region via SSM."
  type        = string
  default     = "" # empty = auto-resolve AL2023 via SSM Parameter Store
}

variable "web_instance_type" {
  description = "EC2 instance type for the web tier"
  type        = string
  default     = "t3.micro"
}

variable "web_min_size" {
  description = "Minimum instances in the web-tier ASG"
  type        = number
  default     = 2
}

variable "web_max_size" {
  description = "Maximum instances in the web-tier ASG"
  type        = number
  default     = 6
}

variable "web_desired_capacity" {
  description = "Desired instances in the web-tier ASG"
  type        = number
  default     = 2
}

# ─────────────────────────────────────────────
# Application Tier
# ─────────────────────────────────────────────
variable "app_ami_id" {
  description = "AMI ID for app-tier EC2 instances. Leave empty to auto-resolve the latest Amazon Linux 2023 AMI for the configured region via SSM."
  type        = string
  default     = "" # empty = auto-resolve AL2023 via SSM Parameter Store
}

variable "app_instance_type" {
  description = "EC2 instance type for the application tier"
  type        = string
  default     = "t3.micro"
}

variable "app_min_size" {
  description = "Minimum instances in the app-tier ASG"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum instances in the app-tier ASG"
  type        = number
  default     = 6
}

variable "app_desired_capacity" {
  description = "Desired instances in the app-tier ASG"
  type        = number
  default     = 2
}

variable "key_pair_name" {
  description = "EC2 Key Pair name — leave empty to rely on SSM Session Manager instead"
  type        = string
  default     = ""
}

# ─────────────────────────────────────────────
# Database Tier
# ─────────────────────────────────────────────
variable "db_engine" {
  description = "Database engine: mysql or postgres"
  type        = string
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "postgres"], var.db_engine)
    error_message = "db_engine must be 'mysql' or 'postgres'."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for RDS autoscaling in GiB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username — set via TF_VAR_db_username env var; do not hardcode"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password — set via TF_VAR_db_password env var; do not hardcode"
  type        = string
  sensitive   = true
}

variable "db_backup_retention_period" {
  description = "Days to retain automated DB backups"
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection"
  type        = bool
  default     = true
}
