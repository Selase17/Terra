# ─────────────────────────────────────────────
# KMS Key for EBS Volume Encryption
# ─────────────────────────────────────────────
resource "aws_kms_key" "ebs" {
  description             = "${var.name} EBS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.name}-ebs-kms-key"
  }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.name}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# ─────────────────────────────────────────────
# Launch Template
# ─────────────────────────────────────────────
resource "aws_launch_template" "main" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  # IMDSv2 required — prevents SSRF-based credential theft
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Encrypted root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
    delete_on_termination       = true
  }

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  monitoring {
    enabled = true
  }

  key_name  = var.key_pair_name != "" ? var.key_pair_name : null
  user_data = var.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.name}-instance"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.name}-volume"
      Environment = var.environment
    }
  }

  tags = {
    Name = "${var.name}-launch-template"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────
# Auto Scaling Group
# ─────────────────────────────────────────────

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}


resource "aws_autoscaling_group" "main" {
  name                = "${var.name}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  health_check_type         = "EC2"
  health_check_grace_period = 120

  # Rolling refresh on launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = {
      Name        = "${var.name}-asg-instance"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# ─────────────────────────────────────────────
# Scaling Policies — CPU utilisation
# ─────────────────────────────────────────────
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Scale out when average CPU > 75%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 25
  alarm_description   = "Scale in when average CPU < 25%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}
