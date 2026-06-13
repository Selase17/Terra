output "web_alb_sg_id" {
  description = "Security group ID for the web-tier ALB"
  value       = aws_security_group.web_alb.id
}

output "web_ec2_sg_id" {
  description = "Security group ID for web-tier EC2 instances"
  value       = aws_security_group.web_ec2.id
}

output "app_alb_sg_id" {
  description = "Security group ID for the app-tier ALB"
  value       = aws_security_group.app_alb.id
}

output "app_ec2_sg_id" {
  description = "Security group ID for app-tier EC2 instances"
  value       = aws_security_group.app_ec2.id
}

output "db_sg_id" {
  description = "Security group ID for the database tier"
  value       = aws_security_group.db.id
}
