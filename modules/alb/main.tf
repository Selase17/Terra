
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  # Hardening
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.logs_bucket
    prefix  = var.logs_prefix
    enabled = true
  }

  tags = {
    Name        = "${var.name}-alb"
    Environment = var.environment
    Scheme      = var.internal ? "internal" : "internet-facing"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200-399"
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  # Faster instance deregistration during rolling deployments
  deregistration_delay = 30

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  tags = {
    Name = "${var.name}-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP listener
# External ALBs redirect HTTP → HTTPS; internal ALBs forward directly
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.internal ? "forward" : "redirect"

    dynamic "forward" {
      for_each = var.internal ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.main.arn
        }
      }
    }

    dynamic "redirect" {
      for_each = var.internal ? [] : [1]
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# HTTPS listener — uncomment once you have an ACM certificate
# resource "aws_lb_listener" "https" {
#   count             = var.internal ? 0 : 1
#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = var.acm_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
# }
