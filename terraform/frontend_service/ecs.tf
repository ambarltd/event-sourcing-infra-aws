locals {
  # Create domain set for easier processing
  domain_set = toset(var.additional_domains)
  all_domains = concat(var.additional_domains, [var.frontend_domain])

  # Simple version - just remove leading * from each domain
  cleaned_domains = [for d in local.all_domains : trimprefix(d, "*")]
  domains_string = join(",", local.cleaned_domains)
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "frontend-cluster"
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/frontend-service"
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

resource "aws_acm_certificate" "domain_certs" {
  for_each = local.domain_set

  domain_name       = each.value
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Certificate validations
resource "aws_acm_certificate_validation" "domain_validations" {
  for_each = aws_acm_certificate.domain_certs

  certificate_arn = each.value.arn

  timeouts {
    create = "10m"
  }
}

# Application Load Balancer (better for web apps)
resource "aws_lb" "alb" {
  name               = "frontend-alb"
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
  certificate_arn   = aws_acm_certificate.nlb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# Target Group for the ALB
resource "aws_lb_target_group" "http" {
  name        = "frontend-tg"
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
  family                   = "frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "frontend-container"
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
      environment = [
        {
          name  = "API_ADDRESS"
          value = "http://${var.backend_endpoint}"
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
          value = local.domains_string
        },
        {
          name  = "LOAD_BALANCER"
          value = aws_lb.alb.dns_name
        },
      ]

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
  name            = "frontend-service"
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
    container_name   = "frontend-container"
    container_port   = var.container_port
  }
}
