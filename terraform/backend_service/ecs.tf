# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment_name}-backend-cluster"
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.environment_name}-backend-service"
  retention_in_days = var.log_retention_days
}

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "nlb_cert" {
  domain_name       = var.backend_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ACM certificate
resource "aws_route53_record" "cert_validation" {
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

# ACM certificate validation
resource "aws_acm_certificate_validation" "nlb_cert_validation" {
  certificate_arn         = aws_acm_certificate.nlb_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}

# Network Load Balancer
resource "aws_lb" "nlb" {
  name               = "${var.environment_name}-backend-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.nlb_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# Target Group for the NLB
resource "aws_lb_target_group" "http" {
  name        = "${var.environment_name}-backend-tg"
  port        = var.container_port
  protocol    = "TCP"
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
  family                   = "${var.environment_name}-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.environment_name}-backend-container"
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
        # Event Store Configuration - from RDS instance
        {
          name  = "EVENT_STORE_HOST"
          value = var.event_store_endpoint
        },
        {
          name  = "EVENT_STORE_PORT"
          value = tostring(var.event_store_port)
        },
        {
          name  = "EVENT_STORE_DATABASE_NAME"
          value = "postgres"
        },
        {
          name  = "EVENT_STORE_USER"
          value = var.event_store_username
        },
        {
          name  = "EVENT_STORE_PASSWORD"
          value = var.event_store_password
        },
        {
          name  = "EVENT_STORE_EVENTS_TABLE_NAME"
          value = "event_store"
        },
        {
          name  = "EVENT_STORE_IDEMPOTENT_REACTION_TABLE_NAME"
          value = "event_store_idempotent_reaction"
        },
        {
          name  = "EVENT_STORE_CREATE_REPLICATION_USER_WITH_USERNAME"
          value = var.event_store_replication_username
        },
        {
          name  = "EVENT_STORE_CREATE_REPLICATION_USER_WITH_PASSWORD"
          value = var.event_store_replication_password
        },
        {
          name  = "EVENT_STORE_CREATE_REPLICATION_PUBLICATION"
          value = "replication_publication"
        },

        # MongoDB Projection Store Configuration - from MongoDB Atlas
        {
          name  = "MONGODB_PROJECTION_HOST"
          value = var.mongodb_host
        },
        {
          name  = "MONGODB_PROJECTION_PORT"
          value = tostring(var.mongodb_port)
        },
        {
          name  = "MONGODB_PROJECTION_AUTHENTICATION_DATABASE"
          value = "admin"
        },
        {
          name  = "MONGODB_PROJECTION_DATABASE_NAME"
          value = "projections"
        },
        {
          name  = "MONGODB_PROJECTION_DATABASE_USERNAME"
          value = var.mongodb_username
        },
        {
          name  = "MONGODB_PROJECTION_DATABASE_PASSWORD"
          value = var.mongodb_password
        },

        # SMTP Configuration - from SES
        {
          name  = "SMTP_HOST"
          value = var.smtp_host
        },
        {
          name  = "SMTP_PORT"
          value = var.smtp_port
        },
        {
          name  = "SMTP_USERNAME"
          value = var.smtp_username
        },
        {
          name  = "SMTP_PASSWORD"
          value = var.smtp_password
        },
        {
          name  = "SMTP_FROM_EMAIL_FOR_ADMINISTRATORS"
          value = var.smtp_from_email
        },

        # Ambar Configuration - hardcoded for now
        {
          name  = "AMBAR_HTTP_USERNAME"
          value = random_string.ambar_user.result
        },
        {
          name  = "AMBAR_HTTP_PASSWORD"
          value = random_password.ambar_pass.result
        },

        # S3 Configuration - using IAM user credentials
        {
          name  = "S3_ENDPOINT_URL"
          value = "https://s3.${var.region}.amazonaws.com"
        },
        {
          name  = "S3_ACCESS_KEY"
          value = var.s3_access_key_id
        },
        {
          name  = "S3_SECRET_KEY"
          value = var.s3_secret_access_key
        },
        {
          name  = "S3_BUCKET_NAME"
          value = var.blob_storage_bucket_name
        },
        {
          name  = "S3_REGION"
          value = var.region
        },
        # Other configs
        {
          name  = "FRONTEND_DOMAIN"
          value = var.frontend_domain
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
  name            = "${var.environment_name}-backend-service"
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
    container_name   = "${var.environment_name}-backend-container"
    container_port   = var.container_port
  }
}

# Route53 A Record for Backend Domain (alias to NLB)
resource "aws_route53_record" "backend" {
  count   = var.backend_domain != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.backend_domain
  type    = "A"

  alias {
    name                   = aws_lb.nlb.dns_name
    zone_id                = aws_lb.nlb.zone_id
    evaluate_target_health = true
  }
}