variable "name" {
  description = "Name prefix for all ALB resources"
  type        = string
}

variable "internal" {
  description = "true = internal ALB; false = internet-facing"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs to attach the ALB to"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the ALB"
  type        = list(string)
}

variable "target_port" {
  description = "Port that the target group sends traffic to"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for the ALB health check"
  type        = string
  default     = "/health"
}

variable "logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "logs_prefix" {
  description = "S3 key prefix for ALB access logs"
  type        = string
  default     = "alb-logs"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (external ALBs)"
  type        = string
  default     = ""
}
