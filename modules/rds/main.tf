# ─────────────────────────────────────────────
# KMS Key for RDS Encryption at Rest
# ─────────────────────────────────────────────
resource "aws_kms_key" "rds" {
  description             = "${var.project_name}-${var.environment} RDS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "kms-${var.project_name}-${var.environment}-rds"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ─────────────────────────────────────────────
# DB Subnet Group
# ─────────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name        = "sng-${var.project_name}-${var.environment}"
  description = "DB subnet group for ${var.project_name} ${var.environment}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "sng-${var.project_name}-${var.environment}"
  }
}

# ─────────────────────────────────────────────
# Parameter Group
# ─────────────────────────────────────────────
resource "aws_db_parameter_group" "main" {
  name        = "pg-${var.project_name}-${var.environment}"
  family      = var.engine == "mysql" ? "mysql8.0" : "postgres15"
  description = "Custom parameter group for ${var.project_name} ${var.environment}"

  dynamic "parameter" {
    for_each = var.engine == "mysql" ? [
      { name = "slow_query_log", value = "1" },
      { name = "long_query_time", value = "2" },
      { name = "log_output", value = "TABLE" }
    ] : []
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = {
    Name = "pg-${var.project_name}-${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────
# Enhanced Monitoring IAM Role
# ─────────────────────────────────────────────
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-${var.project_name}-${var.environment}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "rds-${var.project_name}-${var.environment}-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ─────────────────────────────────────────────
# RDS Instance — Multi-AZ
# ─────────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier = "db-${var.project_name}-${var.environment}"

  # Engine
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  # Database credentials
  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.engine == "mysql" ? 3306 : 5432

  # Networking — never publicly accessible
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # High Availability — synchronous replication to standby in second AZ
  multi_az = false

  # Backups & maintenance
  backup_retention_period    = var.backup_retention_period
  backup_window              = "03:00-04:00"
  maintenance_window         = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot      = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "db-${var.project_name}-${var.environment}-final-snapshot"
  delete_automated_backups   = false
  auto_minor_version_upgrade = true

  # Security
  deletion_protection = var.deletion_protection

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  enabled_cloudwatch_logs_exports = var.engine == "mysql" ? [
    "error", "general", "slowquery"
  ] : ["postgresql", "upgrade"]

  performance_insights_enabled          = false
  performance_insights_retention_period = 0

  tags = {
    Name = "db-${var.project_name}-${var.environment}"
  }

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]
}
