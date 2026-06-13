variable "name" {
  description = "Name prefix for all ASG resources"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 Key Pair name — leave empty to disable SSH (use SSM instead)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to launched instances"
  type        = list(string)
}

variable "target_group_arns" {
  description = "ALB target group ARNs to register instances with"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile to attach"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "user_data" {
  description = "Base64-encoded user data bootstrap script"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
