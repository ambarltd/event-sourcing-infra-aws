locals {
  # Create domain set for easier processing
  domain_set  = toset(var.additional_domains)
  all_domains = concat(var.additional_domains, [var.frontend_domain])
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment_name}-frontend-cluster"
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.environment_name}-frontend-service"
  retention_in_days = var.log_retention_days
}

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "nlb_cert" {
  domain_name       = var.frontend_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for primary certificate
resource "aws_route53_record" "primary_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nlb_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Primary certificate validation
resource "aws_acm_certificate_validation" "primary_cert_validation" {
  certificate_arn         = aws_acm_certificate.nlb_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.primary_cert_validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}

resource "aws_acm_certificate" "domain_certs" {
  for_each = local.domain_set

  domain_name       = each.value
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for additional domain certificates
resource "aws_route53_record" "domain_cert_validation" {
  for_each = {
    for dvo in flatten([
      for cert_key, cert in aws_acm_certificate.domain_certs : [
        for validation in cert.domain_validation_options : {
          key      = "${cert_key}_${validation.domain_name}"
          name     = validation.resource_record_name
          record   = validation.resource_record_value
          type     = validation.resource_record_type
          cert_key = cert_key
        }
      ]
    ]) : dvo.key => dvo
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Certificate validations
resource "aws_acm_certificate_validation" "domain_validations" {
  for_each = aws_acm_certificate.domain_certs

  certificate_arn = each.value.arn
  validation_record_fqdns = [
    for record_key, record in aws_route53_record.domain_cert_validation : record.fqdn
    if startswith(record_key, "${each.key}_")
  ]

  timeouts {
    create = "10m"
  }
}

# Application Load Balancer (better for web apps)
resource "aws_lb" "alb" {
  name               = "${var.environment_name}-frontend-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]

  enable_deletion_protection = true
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_certificate" "additional_certs" {
  for_each = local.domain_set

  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = aws_acm_certificate.domain_certs[each.value].arn

  depends_on = [aws_acm_certificate_validation.domain_validations]
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.primary_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# Target Group for the ALB
resource "aws_lb_target_group" "http" {
  name        = "${var.environment_name}-frontend-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
  }
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment_name}-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.environment_name}-frontend-container"
      image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.ecr_repository_name}:${var.container_image}"
      #
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = concat([
        {
          name  = "API_ADDRESS"
          value = "https://${var.backend_endpoint}"
        },
        {
          name  = "PRODUCTION"
          value = "TRUE"
        },
        {
          name  = "SERVER_PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "SERVER_HOSTNAME"
          value = "::"
        },
        {
          name  = "DOMAIN"
          value = local.all_domains
        },
        {
          name  = "LOAD_BALANCER"
          value = aws_lb.alb.dns_name
        }
      ], var.environment_variables)

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.environment_name}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.http.arn
    container_name   = "${var.environment_name}-frontend-container"
    container_port   = var.container_port
  }
}

# Route53 A Record for Frontend Domain (alias to ALB)
resource "aws_route53_record" "frontend" {
  zone_id = var.hosted_zone_id
  name    = var.frontend_domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
