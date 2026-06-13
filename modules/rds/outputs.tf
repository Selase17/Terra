output "endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}
