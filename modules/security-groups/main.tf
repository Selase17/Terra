# ─────────────────────────────────────────────────────────────────────────────
# Tier 1 — Web ALB Security Group
# Allows HTTP/HTTPS from the public internet
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "web_alb" {
  name        = "${var.project_name}-${var.environment}-web-alb-sg"
  description = "Web ALB: allow inbound HTTP and HTTPS from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Tier 1 — Web EC2 Security Group
# Only accepts traffic forwarded by the Web ALB
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "web_ec2" {
  name        = "${var.project_name}-${var.environment}-web-ec2-sg"
  description = "Web EC2: allow HTTP/HTTPS from web ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from web ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  ingress {
    description     = "HTTPS from web ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Tier 2 — App ALB Security Group  (internal)
# Only accepts traffic from web-tier EC2 instances
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "app_alb" {
  name        = "${var.project_name}-${var.environment}-app-alb-sg"
  description = "App ALB: allow traffic from web EC2 instances only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from web EC2"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_ec2.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Tier 2 — App EC2 Security Group
# Only accepts traffic forwarded by the App ALB
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "app_ec2" {
  name        = "${var.project_name}-${var.environment}-app-ec2-sg"
  description = "App EC2: allow traffic from app ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from app ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb.id]
  }

  egress {
    description = "Allow all outbound (required for NAT/SSM/yum)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Tier 3 — Database Security Group
# Accepts MySQL / PostgreSQL only from app-tier EC2 instances
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "DB: allow MySQL/PostgreSQL from app EC2 only - no public access"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_ec2.id]
  }

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_ec2.id]
  }

  egress {
    description = "Allow outbound (RDS maintenance)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
