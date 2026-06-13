# ─────────────────────────────────────────────────────────────────────────────
# Random suffix to ensure globally-unique S3 bucket names
# ─────────────────────────────────────────────────────────────────────────────
resource "random_id" "suffix" {
  byte_length = 4
}

# ─────────────────────────────────────────────────────────────────────────────
# S3 Bucket — ALB Access Logs
# ─────────────────────────────────────────────────────────────────────────────
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project_name}-${var.environment}-alb-logs-${random_id.suffix.hex}"
  force_destroy = false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-logs"
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────────────────────
# Locals — user data for each tier
# ─────────────────────────────────────────────────────────────────────────────
locals {
  web_user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail
    yum update -y
    yum install -y amazon-cloudwatch-agent nginx
    systemctl enable --now nginx
    mkdir -p /usr/share/nginx/html
    echo "OK" > /usr/share/nginx/html/health
    # Start CloudWatch Agent with default config
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -s -c default
  EOT
  )

  app_user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail
    yum update -y
    yum install -y amazon-cloudwatch-agent python3
    # Minimal health-check HTTP server on port 8080
    python3 -c "
from http.server import HTTPServer, BaseHTTPRequestHandler
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers(); self.wfile.write(b'OK')
    def log_message(self, *a): pass
HTTPServer(('', 8080), H).serve_forever()
" &
  EOT
  )
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: VPC
# ─────────────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: Security Groups
# ─────────────────────────────────────────────────────────────────────────────
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: IAM Roles & Instance Profiles
# ─────────────────────────────────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: Web ALB  (internet-facing)
# ─────────────────────────────────────────────────────────────────────────────
module "web_alb" {
  source = "./modules/alb"

  name               = "${var.project_name}-${var.environment}-web"
  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.web_alb_sg_id]
  target_port        = 80
  health_check_path  = "/health"
  logs_bucket        = aws_s3_bucket.alb_logs.bucket
  logs_prefix        = "web-alb"
  project_name       = var.project_name
  environment        = var.environment

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: Web Auto Scaling Group
# ─────────────────────────────────────────────────────────────────────────────
module "web_asg" {
  source = "./modules/ec2-asg"

  name                 = "${var.project_name}-${var.environment}-web"
  ami_id               = var.web_ami_id
  instance_type        = var.web_instance_type
  key_pair_name        = var.key_pair_name
  subnet_ids           = module.vpc.public_subnet_ids
  security_group_ids   = [module.security_groups.web_ec2_sg_id]
  target_group_arns    = [module.web_alb.target_group_arn]
  iam_instance_profile = module.iam.ec2_instance_profile_name
  min_size             = var.web_min_size
  max_size             = var.web_max_size
  desired_capacity     = var.web_desired_capacity
  user_data            = local.web_user_data
  project_name         = var.project_name
  environment          = var.environment
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: App ALB  (internal)
# ─────────────────────────────────────────────────────────────────────────────
module "app_alb" {
  source = "./modules/alb"

  name               = "${var.project_name}-${var.environment}-app"
  internal           = true
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.app_alb_sg_id]
  target_port        = 8080
  health_check_path  = "/health"
  logs_bucket        = aws_s3_bucket.alb_logs.bucket
  logs_prefix        = "app-alb"
  project_name       = var.project_name
  environment        = var.environment

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: App Auto Scaling Group
# ─────────────────────────────────────────────────────────────────────────────
module "app_asg" {
  source = "./modules/ec2-asg"

  name                 = "${var.project_name}-${var.environment}-app"
  ami_id               = var.app_ami_id
  instance_type        = var.app_instance_type
  key_pair_name        = var.key_pair_name
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_ids   = [module.security_groups.app_ec2_sg_id]
  target_group_arns    = [module.app_alb.target_group_arn]
  iam_instance_profile = module.iam.ec2_instance_profile_name
  min_size             = var.app_min_size
  max_size             = var.app_max_size
  desired_capacity     = var.app_desired_capacity
  user_data            = local.app_user_data
  project_name         = var.project_name
  environment          = var.environment
}

# ─────────────────────────────────────────────────────────────────────────────
# Module: RDS Multi-AZ
# ─────────────────────────────────────────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  subnet_ids              = module.vpc.db_subnet_ids
  security_group_ids      = [module.security_groups.db_sg_id]
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
}
