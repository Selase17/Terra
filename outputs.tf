output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public (web-tier) subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private (app-tier) subnets"
  value       = module.vpc.private_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.db_subnet_ids
}

output "web_alb_dns_name" {
  description = "DNS name of the internet-facing web Application Load Balancer"
  value       = module.web_alb.alb_dns_name
}

output "app_alb_dns_name" {
  description = "DNS name of the internal app Application Load Balancer"
  value       = module.app_alb.alb_dns_name
}

output "web_asg_name" {
  description = "Name of the web-tier Auto Scaling Group"
  value       = module.web_asg.asg_name
}

output "app_asg_name" {
  description = "Name of the app-tier Auto Scaling Group"
  value       = module.app_asg.asg_name
}

output "rds_endpoint" {
  description = "RDS instance connection endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.port
}

output "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  value       = aws_s3_bucket.alb_logs.bucket
}
