# ─────────────────────────────────────────────
# EC2 Instance IAM Role
# ─────────────────────────────────────────────
resource "aws_iam_role" "ec2_instance" {
  name = "${var.project_name}-${var.environment}-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-instance-role"
  }
}

# SSM Session Manager — shell access without opening port 22
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent — push custom metrics and application logs
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ECR read-only — pull container images if containerised workloads are used
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Custom policy — read secrets scoped to this project from SSM Parameter Store
resource "aws_iam_policy" "ssm_parameter_read" {
  name        = "${var.project_name}-${var.environment}-ssm-param-read"
  description = "Allow EC2 instances to read project secrets from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadProjectParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Sid      = "DecryptWithSSMKey"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.*.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_parameter_read" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = aws_iam_policy.ssm_parameter_read.arn
}

# ─────────────────────────────────────────────
# EC2 Instance Profile
# ─────────────────────────────────────────────
resource "aws_iam_instance_profile" "ec2_instance" {
  name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  }
}
